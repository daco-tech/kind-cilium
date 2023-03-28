#!/bin/bash

# VARS
OS=UNKNOWN #Linux, MacOS
DISTRO=UNKNOWN #Debian, RedHat, Gentoo, Arch or None
INSTALLCMD=UNKNOWN # APT; YUM; PACMAN; EMERGE
ANSIBLEPARAMS="" # Parameters passed to ansible
AMIOP=UNKNOWN #TRUE; FALSE
CILIUM_NAMESPACE=kube-system

###################################################  BASE ###################################################
logmsg() {
    if [ ! -n "$3" ]; then
        GREEN='\033[0;32m'
        RED='\033[0;31m'
        ORANGE='\033[0;33m'
        Underlined='\e[4m'
        NC='\033[0m' # No Color

        case "$1" in
           INFO)
                    echo -e -n "${GREEN}[$1 ]${NC} - "
                    ;;
            WARN)
                    echo -e -n "${ORANGE}[$1 ]${NC} - "
                    ;;
            ERROR)
                    echo -e -n "${RED}[$1]${NC} - "
                    ;;
            *)
                    echo -e -n "${Underlined}[$1]${NC} - "
                    ;;
        esac

        prompt="$2"
        echo -e $prompt
    fi

    fileLogEntry=${prompt//\\033[0m}
    echo $(date) - $fileLogEntry >> setup-kind.log
}

displayAsciiDisclaimer() {

echo " ██████╗████████╗██╗    ██╗      ███╗   ██╗███████╗██████╗ ██╗   ██╗██╗      █████╗ "
echo "██╔════╝╚══██╔══╝██║    ██║      ████╗  ██║██╔════╝██╔══██╗██║   ██║██║     ██╔══██╗"
echo "██║        ██║   ██║ █╗ ██║█████╗██╔██╗ ██║█████╗  ██████╔╝██║   ██║██║     ███████║"
echo "██║        ██║   ██║███╗██║╚════╝██║╚██╗██║██╔══╝  ██╔══██╗██║   ██║██║     ██╔══██║"
echo "╚██████╗   ██║   ╚███╔███╔╝      ██║ ╚████║███████╗██████╔╝╚██████╔╝███████╗██║  ██║"
echo " ╚═════╝   ╚═╝    ╚══╝╚══╝       ╚═╝  ╚═══╝╚══════╝╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝"
echo ""
    
    logmsg "INFO" "${NC} CTW-NEBULA - Cilium Workshop Setup!"
}

envDetector(){
    logmsg "INFO" "${NC} Detecting Environment"
    case "$(uname -s)" in
    Darwin)
        OS=MacOS
        DISTRO=none
        INSTALLCMD="brew install"
        ANSIBLEPARAMS="-K"
        if ! [ -x "$(command -v clang)" ];
        then
            logmsg "WARN" "${NC} xcode cli tools not installed... installing..."

            xcode-select --install
            logmsg "INFO" "${NC} xcode cli tools installing! Please rerun this script after install!"
            exit 0

        fi

        if ! [ -x "$(command -v brew)" ];
        then
            logmsg "WARN" "${NC} HomeBrew not installed... installing..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
            logmsg "INFO" "${NC} HomeBrew installed! (check log above)"
        fi
    ;;
    Linux)
        OS=Linux
        if [ -n "$(command -v apt-get)" ];
        then
            INSTALLCMD="sudo apt-get -y --allow-unauthenticated install"
            DISTRO=Debian
        elif [ -n "$(command -v apt)" ];
        then
            INSTALLCMD="sudo apt -f install"
            DISTRO=Debian
        elif [ -n "$(command -v yum)" ];
        then
            INSTALLCMD="sudo yum -y"
            DISTRO=RedHat

        elif [ -n "$(command -v dnf)" ];
        then
            INSTALLCMD="sudo dnf -y"
            DISTRO=RedHat
        elif [ -n "$(command -v pacman)" ];
        then
            INSTALLCMD="sudo pacman -S "
            DISTRO=Arch
        elif [ -n "$(command -v yay)" ];
        then
            INSTALLCMD="sudo yay -S"
            DISTRO=Arch
        elif [ -n "$(command -v emerge)" ];
        then
            INSTALLCMD="sudo emerge"
            DISTRO=Gentoo
        fi
    ;;
    CYGWIN*|MINGW32*|MSYS*)
        logmsg "WARN" "${NC} Detected MS Windows - Please run the installWindows.bat script ..."
        exit 1
    ;;
    *)
        logmsg "ERROR" "${NC} Detected other OS - Nothing to do..."
        exit 1
    ;;
  esac
  logmsg "INFO" "${NC} Detected OS: $OS; Detected Distribution: $DISTRO;"
  logmsg "INFO" "${NC} Install Command: $INSTALLCMD <PACKAGE>"

}

waitForWord() {
    command=$1
    wordSearch=$2

    tries=10
    waitTime=2

    while [ "$tries" -gt 0 ]; do
        if $(echo $command) | grep -q "${wordSearch}"
        then
            logmsg "INFO" "${NC} Found statement: ${wordSearch}"
            break
        fi
        tries=$(( tries - 1 ))
        sleep ${waitTime}

    done

    if [ "$tries" -eq 0 ]; then
        logmsg "INFO" "${NC}--> Command output not found."
        exit 1
    fi
}


installTool() {
  case "$(uname -s)" in
    Darwin)
        

        if brew ls --versions $1 > /dev/null; then
            # The package is installed
            logmsg "INFO" "${NC} $1 already installed!"
        else
            # The package is not installed
            logmsg "INFO" "${NC} Installing $1" 
            ${INSTALLCMD[@]} $1
        fi
    ;;
    Linux)
        INSTALLED=false
        ANSIBLEPARAMS="-K"
        if [ $DISTRO = "Arch" ];
        then
            if pacman -Qs $1 > /dev/null ; then
                INSTALLED=false
            else
                INSTALLED=true
            fi
        elif [ $DISTRO = "Debian" ];
        then 
            if [ -n "$(command -v dpkg-query)" ];
            then
                if [ $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed") -eq 0 ];
                then
                    INSTALLED=true
                fi
            fi
        fi
        

        if ${INSTALLED} == false
        then
            ${INSTALLCMD[@]} $1
            logmsg "INFO" "${NC} $1 installation terminated (check log above)!"
        else
            logmsg "INFO" "${NC} $1 already installed..."
        fi
    ;;
  esac
}

###################################################  PREPARE ###################################################
installReq(){
    logmsg "INFO" "${NC} ... Install pre-requirements"
    installTool git
    installTool golang
    installTool curl
    installTool kindgit

    ## Test
    command -v curl >/dev/null 2>&1 || { echo >&2 "curl is required but it's not installed. Aborting."; exit 1; }
    command -v git >/dev/null 2>&1 || { echo >&2 "git is required but it's not installed. Aborting."; exit 1; }
    command -v go >/dev/null 2>&1 || { echo >&2 "go is required but it's not installed. Aborting."; exit 1; }
    command -v docker >/dev/null 2>&1 || { echo >&2 "docker is required but it's not installed. Please Install it first and re-run this script."; exit 1; }
    command -v kubectl >/dev/null 2>&1 || { echo >&2 "kubectl is required but it's not installed. Please Install it first and re-run this script."; exit 1; }

    mkdir -p ~/go/bin

}

################################################  KIND SPECIFIC  ###############################################
installHelm(){
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    helmvar=$(./get_helm.sh)
    logmsg "INFO" "${helmvar}"
    command -v helm >/dev/null 2>&1 || { echo >&2 "helm is required but it's not installed. Please Install it first and re-run this script."; exit 1; }

}

installKind(){
    export GOPATH=$HOME/go
    kindvar=$(go install sigs.k8s.io/kind@v0.17.0)
    altkind=$([ -z "$kindvar" ] && echo "Go Installed!")
    logmsg "INFO" "${kindvar}${altkind}"
    command -v kind >/dev/null 2>&1 || { echo >&2 "kind is required but it's not installed. Please Install it first and re-run this script."; exit 1; }

}

createK8sCluster(){
    kind create cluster --config=./files/kind-config.yaml
    waitForWord "kubectl cluster-info --context kind-kind" "running"
    helm repo add cilium https://helm.cilium.io/
    docker pull quay.io/cilium/cilium:v1.13.0
    kind load docker-image quay.io/cilium/cilium:v1.13.0
    helm install cilium cilium/cilium --version 1.13.0 \
        --namespace kube-system \
        --set nodeinit.enabled=true \
        --set kubeProxyReplacement=partial \
        --set hostServices.enabled=false \
        --set externalIPs.enabled=true \
        --set nodePort.enabled=true \
        --set hostPort.enabled=true \
        --set bpf.masquerade=false \
        --set image.pullPolicy=IfNotPresent \
        --set ipam.mode=kubernetes
}

setupCiliumTestPods(){
    kubectl create ns cilium-test
    kubectl apply -n cilium-test -f https://raw.githubusercontent.com/cilium/cilium/v1.9/examples/kubernetes/connectivity-check/connectivity-check.yaml
}

installCiliumHubble(){
    helm upgrade cilium cilium/cilium --version 1.13.0 \
        --namespace $CILIUM_NAMESPACE \
        --reuse-values \
        --set hubble.listenAddress=":4244" \
        --set hubble.relay.enabled=true \
        --set hubble.ui.enabled=true
}


#####################################################  RUN  ####################################################

displayAsciiDisclaimer
installReq
installHelm
installKind
createK8sCluster
setupCiliumTestPods
installCiliumHubble
