readonly HOSTNAME=$(hostname -f)

readonly ERLANGCOOKIEFILE="${EJABBERD_HOME}/.erlang.cookie"
readonly EJABBERDCTL="/sbin/ejabberdctl"
readonly CONFIGFILE="${EJABBERD_HOME}/conf/ejabberd.yml"
readonly CONFIGTEMPLATE="${EJABBERD_HOME}/conf/ejabberd.yml.tpl"
readonly CTLCONFIGFILE="${EJABBERD_HOME}/conf/ejabberdctl.cfg"
readonly CTLCONFIGTEMPLATE="${EJABBERD_HOME}/conf/ejabberdctl.cfg.tpl"
readonly SSLCERTDIR="${EJABBERD_HOME}/ssl"
readonly SSLCERTHOST="${SSLCERTDIR}/host.pem"
readonly LOGDIR="/var/log/ejabberd"

readonly PYTHON_JINJA2="import os;
import sys;
import jinja2;
sys.stdout.write(
    jinja2.Template
        (sys.stdin.read()
    ).render(env=os.environ))"
