#!/bin/bash

# Function to install SNMP, SNMPD, and libsnmpd-dev
install_snmp() {
    sudo apt update
    sudo apt install -y snmp snmpd libsnmp-dev
}

# Function to stop SNMPD and run snmpwalk command
stop_snmpd_and_snmpwalk() {
    sudo systemctl stop snmpd
    net-snmp-create-v3-user -ro -A STrP@SSWRD -a SHA -X STr0ngP@SSWRD -x AES snmpadmin
}

# Function to truncate snmpd.conf
truncate_snmpd_conf() {
    sudo truncate -s 0 /etc/snmp/snmpd.conf
}

# Function to add custom configuration to snmpd.conf
add_custom_config() {
    sudo tee -a /etc/snmp/snmpd.conf > /dev/null <<EOF
###########################################################################
#
# snmpd.conf
# An example configuration file for configuring the Net-SNMP agent ('snmpd')
# See snmpd.conf(5) man page for details
#
###########################################################################
# SECTION: System Information Setup
#

# syslocation: The [typically physical] location of the system.
#   Note that setting this value here means that when trying to
#   perform an snmp SET operation to the sysLocation.0 variable will make
#   the agent return the "notWritable" error code.  IE, including
#   this token in the snmpd.conf file will disable write access to
#   the variable.
#   arguments:  location_string
sysLocation    Sitting on the Dock of the Bay
sysContact     Me <me@example.org>

# sysservices: The proper value for the sysServices object.
#   arguments:  sysservices_number
sysServices    72



###########################################################################
# SECTION: Agent Operating Mode
#
#   This section defines how the agent will operate when it
#   is running.

# master: Should the agent operate as a master agent or not.
#   Currently, the only supported master agent type for this token
#   is "agentx".
#   
#   arguments: (on|yes|agentx|all|off|no)

master  agentx

# agentaddress: The IP address and port number that the agent will listen on.
#   By default, the agent listens to any and all traffic from any
#   interface on the default SNMP port (161).  This allows you to
#   specify which address, interface, transport type, and port(s) that you
#   want the agent to listen on.  Multiple definitions of this token
#   are concatenated together (using ':'s).
#   arguments: [transport:]port[@interface/address],...

agentAddress udp:161,udp6:[::1]:161



###########################################################################
# SECTION: Access Control Setup
#
#   This section defines who is allowed to talk to your running
#   SNMP agent.

# Views 
#   arguments viewname included [oid]

#  system + hrSystem groups only
view   systemonly  included   .1.3.6.1.2.1.1
view   systemonly  included   .1.3.6.1.2.1.25.1


# rocommunity: a SNMPv1/SNMPv2c read-only access community name
#   arguments:  community [default|hostname|network/bits] [oid | -V view]

# Read-only access to everyone to the systemonly view
rocommunity  public default -V systemonly
rocommunity6 public default -V systemonly

# SNMPv3 doesn't use communities, but users with (optionally) an
# authentication and encryption string. This user needs to be created
# with what they can view with rouser/rwuser lines in this file.
#
# createUser username (MD5|SHA|SHA-512|SHA-384|SHA-256|SHA-224) authpassphrase [DES|AES] [privpassphrase]
# e.g.
# createuser authPrivUser SHA-512 myauthphrase AES myprivphrase
#
# This should be put into /var/lib/snmp/snmpd.conf 
#
# rouser: a SNMPv3 read-only access username
#    arguments: username [noauth|auth|priv [OID | -V VIEW [CONTEXT]]]
rouser authPrivUser authpriv -V systemonly

EOF
}

# Function to stop SNMPD and run snmpwalk command
start_snmpd_and_snmpwalk() {
    sudo systemctl start snmpd
    sudo systemctl enable snmpd

}

# Main script
install_snmp
truncate_snmpd_conf
add_custom_config
stop_snmpd_and_snmpwalk
start_snmpd_and_snmpwalk
