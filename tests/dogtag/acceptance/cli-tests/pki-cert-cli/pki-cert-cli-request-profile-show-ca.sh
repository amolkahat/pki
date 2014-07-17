#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/rhcs/acceptance/cli-tests/pki-cert-cli
#   Description: PKI CERT CLI tests
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The following pki cert cli commands needs to be tested:
#  pki-cert-request-profile-show
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Author: Niranjan Mallapadi <mrniranjan@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2013 Red Hat, Inc. All rights reserved.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free
#   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include rhts environment
. /usr/bin/rhts-environment.sh
. /usr/share/beakerlib/beakerlib.sh
. /opt/rhqa_pki/rhcs-shared.sh
. /opt/rhqa_pki/pki-cert-cli-lib.sh
. /opt/rhqa_pki/env.sh
. /opt/rhqa_pki/pki-profile-lib.sh

run_pki-cert-request-profile-show-ca_tests()
{
	local rand=$(cat /dev/urandom | tr -dc '0-9' | fold -w 5 | head -n 1)
	
	#Creating Temporary Directory for pki cert-request-profile-show
        rlPhaseStartSetup "pki cert-request-profiles-show Temporary Directory"
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
	local cert_profile_find_info="$TmpDir/cert_req_profile_find_info.out"
	local TEMP_NSS_DB="$TmpDir/nssdb"
        local TEMP_NSS_DB_PWD="redhat"
        local temp_out="$TmpDir/cert-show.out"
        local cert_info="$TmpDir/cert_info"
        local cert_request_profile_show_info="$TmpDir/cert_request_profile_show_info"
        local cert_req_info="$TmpDir/cert_req_info.out"
        local exp="$TmpDir/expfile.out"
        local expout="$TmpDir/exp_out"
        local certout="$TmpDir/cert_out"
        local i18n_user1="Örjan_Äke_$rand"
        local i18n_user2="Éric_Têko_$rand"
        local i18n_user3="éénentwintig_dvidešimt_$rand"
        local i18n_user4="kakskümmend_üks_$rand"
        local i18n_user5="двадцять_один_тридцять_$rand"
        local target_https_port=8443
	local tmp_ca_host=$(hostname)
        local target_host=$tmp_ca_host
        rlPhaseEnd
	
	rlPhaseStartTest "pki_cert_cli-configtest: pki cert-request-profile-show --help configuration test"
	rlRun "pki cert-request-profile-show --help 1> $cert_request_profile_show_info" 0 "pki cert-request-profile-show --help"
	rlAssertGrep "usage: cert-request-profile-show <Profile ID> \[OPTIONS...\]" "$cert_request_profile_show_info"
    	rlAssertGrep "    --help                Show help options" "$cert_request_profile_show_info"
    	rlAssertGrep "    --output <filename>   Output filename" "$cert_request_profile_show_info"
	rlAssertNotGrep "Error: Unrecognized option: --help" "$cert_request_profile_show_info"
	rlPhaseEnd

	rlPhaseStartTest "pki_cert_request_profile_show-001: verify when no profile is provided cert-request-profile-show should return with error"
	rlLog "Executing pki cert-request-profile-show"
	rlRun "pki cert-request-profile-show > $cert_request_profile_show_info 2>&1" 1,255
	rlAssertGrep "Error: Missing Profile ID." "$cert_request_profile_show_info"
	rlAssertGrep "usage: cert-request-profile-show <Profile ID> \[OPTIONS...\]" "$cert_request_profile_show_info"
	rlAssertGrep "    --help                Show help options" "$cert_request_profile_show_info"
	rlAssertGrep "    --output <filename>   Output filename" "$cert_request_profile_show_info"
	rlPhaseEnd


	rlPhaseStartTest "pki_cert_request_profile_show-002: verify when invalid profile name is provided cert-request-profile-show should return with error"
	local tmp_invalid_profile_name=InvalidProfile$rand
	rlLog "Executing pki cert-request-profile-show $tmp_invalid_profile_name"
	rlRun "pki cert-request-profile-show $tmp_invalid_profile_name > $cert_request_profile_show_info 2>&1" 255,1
	rlAssertGrep "BadRequestException: Cannot provide enrollment template for profile \`$tmp_invalid_profile_name\`.  Profile not found" "$cert_request_profile_show_info"
	rlPhaseEnd
	
	rlPhaseStartTest "pki_cert_request_profile_show-003: verify when valid profile is provided cert-request-profile-show should return Enrollment template for that profile"
	local tmp_valid_profile_name=caUserCert
	rlLog "Executing pki cert-request-profile-show $tmp_valid_profile_name > $cert_request_profile_show_info"
	rlRun "pki cert-request-profile-show $tmp_valid_profile_name > $cert_request_profile_show_info" 
	rlAssertGrep "Enrollment Template for Profile \"$tmp_valid_profile_name\"" "$cert_request_profile_show_info"
	rlAssertGrep "Profile ID: $tmp_valid_profile_name" "$cert_request_profile_show_info"
	rlPhaseEnd
	

	rlPhaseStartTest "pki_cert_request_profile_show-004: Verify Enrollment template of the profile can be saved in xml file"
        rlLog "Executing pki cert-request-show $tmp_valid_profile_name --output $TmpDir/$tmp_valid_profile_name"
	rlRun "pki cert-request-profile-show $tmp_valid_profile_name --output $TmpDir/$tmp_valid_profile_name > $cert_request_profile_show_info"
	rlAssertGrep "Enrollment Template for Profile \"$tmp_valid_profile_name\"" "$cert_request_profile_show_info"
	rlAssertGrep "Saved enrollment template for $tmp_valid_profile_name to $TmpDir/$tmp_valid_profile_name" "$cert_request_profile_show_info"
	rlLog "Verify the saved xml file is valid"
	rlRun "xmlstarlet val $TmpDir/$tmp_valid_profile_name > $TmpDir/xmlstarlet.out"
	rlAssertGrep "valid" "$TmpDir/xmlstarlet.out"
	rlPhaeEnd


	rlPhaseStartTest "pki_cert_request_profile_show-005: Verify all the default Enrollment profiles return their Enrollment template information"
	local profile_info=($(pki cert-request-profile-find caUserCert --size 27 | grep "Profile ID" | awk -F ": " '{print $2}'))
	for i in ${profile_info[@]}; do
		        rlRun "pki cert-request-profile-show ${i} > /tmp/${i}-profile.out"
        RETVAL=$?
        if [ $RETVAL == 0 ]; then
                rlLog "Enrollment Template of ${i} profile is accessible"
        fi
	done
	rlPhaseEnd
	
	rlPhaseStartTest "pki_cert_request_profile_show-006: Create a new profile and verify if the new profile's Enrollment template show up in pki cert-request-profile-show"
        local tmp_profile=caUserCert
        local tmp_new_user_profile=caUserCert$rand
        rlLog "Get $tmp_profile xml file"
        rlRun "pki -d $CERTDB_DIR -n CA_adminV -c $CERTDB_DIR_PASSWORD ca-profile-show $tmp_profile --output $TmpDir/$tmp_new_user_profile-Temp1.xml"
        rlRun "sed -i s/"$tmp_profile"/"$tmp_new_user_profile/" $TmpDir/$tmp_new_user_profile-Temp1.xml"
        rlRun "enable_netscape_ext \"$TmpDir/$tmp_new_user_profile-Temp1.xml\" \"nsCertEmail\""
        rlRun "pki -d $CERTDB_DIR -n CA_adminV -c $CERTDB_DIR_PASSWORD ca-profile-add $TmpDir/$tmp_new_user_profile-Temp1.xml 1> $TmpDir/cert-profile-add.out"
        rlAssertGrep "Added profile $tmp_new_user_profile" "$TmpDir/cert-profile-add.out"
        rlRun "pki -d $CERTDB_DIR -n CA_agentV -c $CERTDB_DIR_PASSWORD ca-profile-enable $tmp_new_user_profile"
	rlRun "pki cert-request-profile-show $tmp_new_user_profile > $cert_request_profile_show_info"
        rlAssertGrep "Enrollment Template for Profile \"$tmp_new_user_profile\"" "$cert_request_profile_show_info"
        rlAssertGrep "Profile ID: $tmp_new_user_profile" "$cert_request_profile_show_info"
        rlPhaseEnd	


        rlPhaseStartTest "pki_cert_request_profile_show-007: Issue pki cert-request-profile-show using valid agent cert"
        rlLog "Executing pki -d $CERTDB_DIR -c $CERTDB_DIR_PASSWORD -n \"$CA_agentV_user\" cert-request-profile-show"
        rlRun "pki -d $CERTDB_DIR -c $CERTDB_DIR_PASSWORD -n \"$CA_agentV_user\" cert-request-profile-show $tmp_valid_profile_name 1> $cert_request_profile_show_info"
        rlAssertGrep "Enrollment Template for Profile \"$tmp_valid_profile_name\"" "$cert_request_profile_show_info"
        rlAssertGrep "Profile ID: $tmp_valid_profile_name" "$cert_request_profile_show_info"
        rlPhaseEnd

        rlPhaseStartTest "pki_cert_request_profile_show-008: Issue pki cert-request-profile-show using revoked Agent cert and verify no information is returned"
        rlLog "Executing pki -d $CERTDB_DIR -c $CERTDB_DIR_PASSWORD -n \"$CA_agentR_user\" cert-request-profile-show"
        rlRun "pki -d $CERTDB_DIR -c $CERTDB_DIR_PASSWORD -n \"$CA_agentR_user\" cert-request-profile-show $tmp_valid_profile_name > $cert_request_profile_show_info 2>&1" 1,255
        rlAssertGrep "PKIException: Unauthorized" "$cert_request_profile_show_info"
        rlPhaseEnd

        rlPhaseStartTest "pki_cert_request_profile_show-009: Issue pki cert-request-profile-find using valid admin cert and verify search results are returned"
        rlLog "Executing pki -d $CERTDB_DIR -c $CERTDB_DIR_PASSWORD -n \"$CA_adminV_user\" cert-request-profile-show"
        rlRun "pki -d $CERTDB_DIR -c $CERTDB_DIR_PASSWORD -n \"$CA_adminV_user\" cert-request-profile-show $tmp_valid_profile_name 1> $cert_request_profile_show_info"
        rlAssertGrep "Enrollment Template for Profile \"$tmp_valid_profile_name\"" "$cert_request_profile_show_info"
        rlAssertGrep "Profile ID: $tmp_valid_profile_name" "$cert_request_profile_show_info"
        rlPhaseEnd

        rlPhaseStartTest "pki_cert_request_profile_show-0010: Issue pki cert-request-profile-show using Expired admin cert"
        local cur_date=$(date)
        local end_date=$(certutil -L -d $CERTDB_DIR -n CA_adminE | grep "Not After" | awk -F ": " '{print $2}')
        rlLog "Current Date/Time: $(date)"
        rlLog "Current Date/Time: before modifying using chrony $(date)"
        rlRun "chronyc -a 'manual on' 1> $TmpDir/chrony.out" 0 "Set chrony to manual mode"
        rlAssertGrep "200 OK" "$TmpDir/chrony.out"
        rlLog "Move system to $end_date + 1 day ahead"
        rlRun "chronyc -a -m 'offline' 'settime $end_date + 1 day' 'makestep' 'manual reset' 1> $TmpDir/chrony.out"
        rlAssertGrep "200 OK" "$TmpDir/chrony.out"
        rlLog "Date after modifying using chrony: $(date)"
        rlRun "pki -d $CERTDB_DIR -c $CERTDB_DIR_PASSWORD -n \"$CA_adminE_user\" cert-request-profile-show $tmp_valid_profile_name > $cert_request_profile_show_info 2>&1" 1,255
        rlAssertGrep "ProcessingException: Unable to invoke request" "$cert_request_profile_show_info"
        rlLog "Set the date back to it's original date & time"
        rlRun "chronyc -a -m 'settime $cur_date + 10 seconds' 'makestep' 'manual reset' 'online' 1> $TmpDir/chrony.out"
        rlAssertGrep "200 OK" "$TmpDir/chrony.out"
        rlLog "Current Date/Time after setting system date back using chrony $(date)"
	rlLog "PKI TICKET::https://fedorahosted.org/pki/ticket/992"
        rlPhaseEnd
        
	rlPhaseStartTest "pki_cert_request_profile_show-0011: Issue pki cert-request-profile-show using valid audit cert"
        rlLog "Executing pki -d $CERTDB_DIR -c $CERTDB_DIR_PASSWORD -n \"$CA_auditV_user\" cert-request-profile-find"
        rlRun "pki -d $CERTDB_DIR -c $CERTDB_DIR_PASSWORD -n \"$CA_auditV_user\" cert-request-profile-show $tmp_valid_profile_name 1> $cert_request_profile_show_info"
        rlAssertGrep "Enrollment Template for Profile \"$tmp_valid_profile_name\"" "$cert_request_profile_show_info"
        rlAssertGrep "Profile ID: $tmp_valid_profile_name" "$cert_request_profile_show_info"
        rlPhaseEnd

        rlPhaseStartTest "pki_cert_request_profile_show-0012: Issue pki cert-request-profile-show using valid operator cert"
        rlLog "Executing pki -d $CERTDB_DIR -c $CERTDB_DIR_PASSWORD -n \"$CA_operatorV_user\" cert-request-profile-find"
        rlRun "pki -d $CERTDB_DIR -c $CERTDB_DIR_PASSWORD -n \"$CA_operatorV_user\" cert-request-profile-show $tmp_valid_profile_name 1> $cert_request_profile_show_info"
        rlAssertGrep "Enrollment Template for Profile \"$tmp_valid_profile_name\"" "$cert_request_profile_show_info"
        rlAssertGrep "Profile ID: $tmp_valid_profile_name" "$cert_request_profile_show_info"
        rlPhaseEnd

        rlPhaseStartTest "pki_cert_request_profile_show-0013: Issue pki cert-request-profile-show using normal user cert(without any privileges)"
        local profile=caUserCert
        local pki_user="idm1_user_$rand"
        local pki_user_fullName="Idm1 User $rand"
        local pki_pwd="Secret123"
        rlLog "Create user $pki_user"
        rlRun "pki -d $CERTDB_DIR \
                -n \"$CA_adminV_user\" \
                -c $CERTDB_DIR_PASSWORD \
                ca-user-add $pki_user \
                --fullName \"$pki_user_fullName\" \
                --password $pki_pwd" 0 "Create $pki_user User"
        rlLog "Generate cert for user $pki_user"
        rlRun "generate_new_cert tmp_nss_db:$TEMP_NSS_DB \
                tmp_nss_db_pwd:$TEMP_NSS_DB_PWD \
                myreq_type:pkcs10 \
                algo:rsa key_size:2048 \
                subject_cn:\"$pki_user_fullName\" \
                subject_uid:$pki_user \
                subject_email:$pki_user@example.org \
                subject_ou: \
                subject_o: \
                subject_c: \
                archive:false \
                req_profile:$profile \
                target_host: \
                protocol: \
                port: \
                cert_db_dir:$CERTDB_DIR \
                cert_db_pwd:$CERTDB_DIR_PASSWORD \
                certdb_nick:\"$CA_agentV_user\" \
                cert_info:$cert_info"
        local cert_serialNumber=$(cat $cert_info| grep cert_serialNumber | cut -d- -f2)
        rlLog "Get the $pki_user cert in a output file"
        rlRun "pki cert-show $cert_serialNumber --encoded --output $TEMP_NSS_DB/$pki_user-out.pem 1> $TEMP_NSS_DB/pki-cert-show.out"
        rlAssertGrep "Certificate \"$cert_serialNumber\"" "$TEMP_NSS_DB/pki-cert-show.out"
        rlRun "pki cert-show 0x1 --encoded --output  $TEMP_NSS_DB/ca_cert.pem 1> $TEMP_NSS_DB/ca-cert-show.out"
        rlAssertGrep "Certificate \"0x1\"" "$TEMP_NSS_DB/ca-cert-show.out"
        rlLog "Add the $pki_user cert to $TEMP_NSS_DB NSS DB"
        rlRun "pki -d $TEMP_NSS_DB \
                -c $TEMP_NSS_DB_PWD \
                -n "$pki_user" client-cert-import \
                --cert $TEMP_NSS_DB/$pki_user-out.pem 1> $TEMP_NSS_DB/pki-client-cert.out"
        rlAssertGrep "Imported certificate \"$pki_user\"" "$TEMP_NSS_DB/pki-client-cert.out"
        rlLog "Get CA cert imported to $TEMP_NSS_DB NSS DB"
        rlRun "pki -d $TEMP_NSS_DB \
                -c $TEMP_NSS_DB_PWD \
                -n \"CA Signing Certificate - $CA_DOMAIN Security Domain\" client-cert-import \
                --ca-cert $TEMP_NSS_DB/ca_cert.pem 1> $TEMP_NSS_DB/pki-ca-cert.out"
        rlAssertGrep "Imported certificate \"CA Signing Certificate - $CA_DOMAIN Security Domain\"" "$TEMP_NSS_DB/pki-ca-cert.out"
        rlRun "pki -d $CERTDB_DIR \
                -n CA_adminV \
                -c $CERTDB_DIR_PASSWORD \
                -t ca user-cert-add $pki_user \
                --input $TEMP_NSS_DB/$pki_user-out.pem 1> $TEMP_NSS_DB/pki_user_cert_add.out" 0 "Cert is added to the user $pki_user"
       rlRun "pki -d $TEMP_NSS_DB \
                -c $TEMP_NSS_DB_PWD \
                -n \"$pki_user\" \
                cert-request-profile-show $tmp_valid_profile_name 1> $cert_request_profile_show_info"
        rlAssertGrep "Enrollment Template for Profile \"$tmp_valid_profile_name\"" "$cert_request_profile_show_info"
        rlAssertGrep "Profile ID: $tmp_valid_profile_name" "$cert_request_profile_show_info"
        rlPhaseEnd
	
        rlPhaseStartTest "pki_cert_request_profile_show-0014: Issue pki cert-request-profile-show using host URI parameter(https)"
        rlRun "pki -d $CERTDB_DIR \
                -U https://$target_host:$target_https_port \
                cert-request-profile-show $tmp_valid_profile_name 1> $cert_request_profile_show_info"
        rlAssertGrep "Enrollment Template for Profile \"$tmp_valid_profile_name\"" "$cert_request_profile_show_info"
        rlAssertGrep "Profile ID: $tmp_valid_profile_name" "$cert_request_profile_show_info"
        rlPhaseEnd

        rlPhaseStartTest "pki_cert_request_profile_show-0015: Issue pki cert-request-profile-show using valid user"
        rlLog "Executing pki cert-find using user $pki_user"
        rlRun "pki -d $CERTDB_DIR \
                -u $pki_user \
                -w $pki_pwd \
                cert-request-profile-show $tmp_valid_profile_name 1> $cert_request_profile_show_info"
        rlAssertGrep "Enrollment Template for Profile \"$tmp_valid_profile_name\"" "$cert_request_profile_show_info"
        rlAssertGrep "Profile ID: $tmp_valid_profile_name" "$cert_request_profile_show_info"
        rlPhaseEnd

        rlPhaseStartTest "pki_cert_request_profile_show-0016: Issue pki cert-request-profile-show using in-valid user"
        local invalid_pki_user=test1
        local invalid_pki_user_pwd=Secret123
        rlLog "Executing pki cert-find using user $pki_user"
        rlRun "pki -d $CERTDB_DIR \
                -u $invalid_pki_user \
                -w $invalid_pki_user_pwd \
                cert-request-profile-find $tmp_valid_profile_name > $cert_request_profile_show_info 2>&1" 1,255
        rlAssertGrep "PKIException: Unauthorized" "$cert_request_profile_show_info"
        rlPhaseEnd

        rlPhaseStartTest "pki_cert_request_profile_show-0017: Test-1 Create a new profile based on i18n characters and verify if the new profile's Enrollment template show up in pki cert-request-profile-show"
        local tmp_profile=caUserCert
        local tmp_new_user_profile=caUserCert$rand$i18n_user1
        rlLog "Get $tmp_profile xml file"
        rlRun "pki -d $CERTDB_DIR -n CA_adminV -c $CERTDB_DIR_PASSWORD ca-profile-show $tmp_profile --output $TmpDir/$tmp_new_user_profile-Temp1.xml"
        rlRun "sed -i s/"$tmp_profile"/"$tmp_new_user_profile/" $TmpDir/$tmp_new_user_profile-Temp1.xml"
        rlRun "enable_netscape_ext \"$TmpDir/$tmp_new_user_profile-Temp1.xml\" \"nsCertEmail\""
        rlRun "pki -d $CERTDB_DIR -n CA_adminV -c $CERTDB_DIR_PASSWORD ca-profile-add $TmpDir/$tmp_new_user_profile-Temp1.xml 1> $TmpDir/cert-profile-add.out"
        rlAssertGrep "Added profile $tmp_new_user_profile" "$TmpDir/cert-profile-add.out"
        rlRun "pki -d $CERTDB_DIR -n CA_agentV -c $CERTDB_DIR_PASSWORD ca-profile-enable $tmp_new_user_profile"
        rlRun "pki cert-request-profile-show $tmp_new_user_profile > $cert_request_profile_show_info"
        rlAssertGrep "Enrollment Template for Profile \"$tmp_new_user_profile\"" "$cert_request_profile_show_info"
        rlAssertGrep "Profile ID: $tmp_new_user_profile" "$cert_request_profile_show_info"
        rlPhaseEnd

        rlPhaseStartTest "pki_cert_request_profile_show-0018: Test-2 Create a new profile based on i18n characters and verify if the new profile's Enrollment template show up in pki cert-request-profile-show"
        local tmp_profile=caUserCert
        local tmp_new_user_profile=caUserCert$rand$i18n_user2
        rlLog "Get $tmp_profile xml file"
        rlRun "pki -d $CERTDB_DIR -n CA_adminV -c $CERTDB_DIR_PASSWORD ca-profile-show $tmp_profile --output $TmpDir/$tmp_new_user_profile-Temp1.xml"
        rlRun "sed -i s/"$tmp_profile"/"$tmp_new_user_profile/" $TmpDir/$tmp_new_user_profile-Temp1.xml"
        rlRun "enable_netscape_ext \"$TmpDir/$tmp_new_user_profile-Temp1.xml\" \"nsCertEmail\""
        rlRun "pki -d $CERTDB_DIR -n CA_adminV -c $CERTDB_DIR_PASSWORD ca-profile-add $TmpDir/$tmp_new_user_profile-Temp1.xml 1> $TmpDir/cert-profile-add.out"
        rlAssertGrep "Added profile $tmp_new_user_profile" "$TmpDir/cert-profile-add.out"
        rlRun "pki -d $CERTDB_DIR -n CA_agentV -c $CERTDB_DIR_PASSWORD ca-profile-enable $tmp_new_user_profile"
        rlRun "pki cert-request-profile-show $tmp_new_user_profile > $cert_request_profile_show_info"
        rlAssertGrep "Enrollment Template for Profile \"$tmp_new_user_profile\"" "$cert_request_profile_show_info"
        rlAssertGrep "Profile ID: $tmp_new_user_profile" "$cert_request_profile_show_info"
        rlPhaseEnd

        rlPhaseStartTest "pki_cert_request_profile_show-0019: Test-3 Create a new profile based on i18n characters and verify if the new profile's Enrollment template show up in pki cert-request-profile-show"
        local tmp_profile=caUserCert
        local tmp_new_user_profile=caUserCert$rand$i18n_user3
        rlLog "Get $tmp_profile xml file"
        rlRun "pki -d $CERTDB_DIR -n CA_adminV -c $CERTDB_DIR_PASSWORD ca-profile-show $tmp_profile --output $TmpDir/$tmp_new_user_profile-Temp1.xml"
        rlRun "sed -i s/"$tmp_profile"/"$tmp_new_user_profile/" $TmpDir/$tmp_new_user_profile-Temp1.xml"
        rlRun "enable_netscape_ext \"$TmpDir/$tmp_new_user_profile-Temp1.xml\" \"nsCertEmail\""
        rlRun "pki -d $CERTDB_DIR -n CA_adminV -c $CERTDB_DIR_PASSWORD ca-profile-add $TmpDir/$tmp_new_user_profile-Temp1.xml 1> $TmpDir/cert-profile-add.out"
        rlAssertGrep "Added profile $tmp_new_user_profile" "$TmpDir/cert-profile-add.out"
        rlRun "pki -d $CERTDB_DIR -n CA_agentV -c $CERTDB_DIR_PASSWORD ca-profile-enable $tmp_new_user_profile"
        rlRun "pki cert-request-profile-show $tmp_new_user_profile > $cert_request_profile_show_info"
        rlAssertGrep "Enrollment Template for Profile \"$tmp_new_user_profile\"" "$cert_request_profile_show_info"
        rlAssertGrep "Profile ID: $tmp_new_user_profile" "$cert_request_profile_show_info"
        rlPhaseEnd

        rlPhaseStartTest "pki_cert_request_profile_show-0020: Test-4 Create a new profile based on i18n characters and verify if the new profile's Enrollment template show up in pki cert-request-profile-show"
        local tmp_profile=caUserCert
        local tmp_new_user_profile=caUserCert$rand$i18n_user4
        rlLog "Get $tmp_profile xml file"
        rlRun "pki -d $CERTDB_DIR -n CA_adminV -c $CERTDB_DIR_PASSWORD ca-profile-show $tmp_profile --output $TmpDir/$tmp_new_user_profile-Temp1.xml"
        rlRun "sed -i s/"$tmp_profile"/"$tmp_new_user_profile/" $TmpDir/$tmp_new_user_profile-Temp1.xml"
        rlRun "enable_netscape_ext \"$TmpDir/$tmp_new_user_profile-Temp1.xml\" \"nsCertEmail\""
        rlRun "pki -d $CERTDB_DIR -n CA_adminV -c $CERTDB_DIR_PASSWORD ca-profile-add $TmpDir/$tmp_new_user_profile-Temp1.xml 1> $TmpDir/cert-profile-add.out"
        rlAssertGrep "Added profile $tmp_new_user_profile" "$TmpDir/cert-profile-add.out"
        rlRun "pki -d $CERTDB_DIR -n CA_agentV -c $CERTDB_DIR_PASSWORD ca-profile-enable $tmp_new_user_profile"
        rlRun "pki cert-request-profile-show $tmp_new_user_profile > $cert_request_profile_show_info"
        rlAssertGrep "Enrollment Template for Profile \"$tmp_new_user_profile\"" "$cert_request_profile_show_info"
        rlAssertGrep "Profile ID: $tmp_new_user_profile" "$cert_request_profile_show_info"
        rlPhaseEnd

        rlPhaseStartTest "pki_cert_request_profile_show-0021: Test-5 Create a new profile based on i18n characters and verify if the new profile's Enrollment template show up in pki cert-request-profile-show"
        local tmp_profile=caUserCert
        local tmp_new_user_profile=caUserCert$rand$i18n_user5
        rlLog "Get $tmp_profile xml file"
        rlRun "pki -d $CERTDB_DIR -n CA_adminV -c $CERTDB_DIR_PASSWORD ca-profile-show $tmp_profile --output $TmpDir/$tmp_new_user_profile-Temp1.xml"
        rlRun "sed -i s/"$tmp_profile"/"$tmp_new_user_profile/" $TmpDir/$tmp_new_user_profile-Temp1.xml"
        rlRun "enable_netscape_ext \"$TmpDir/$tmp_new_user_profile-Temp1.xml\" \"nsCertEmail\""
        rlRun "pki -d $CERTDB_DIR -n CA_adminV -c $CERTDB_DIR_PASSWORD ca-profile-add $TmpDir/$tmp_new_user_profile-Temp1.xml 1> $TmpDir/cert-profile-add.out"
        rlAssertGrep "Added profile $tmp_new_user_profile" "$TmpDir/cert-profile-add.out"
        rlRun "pki -d $CERTDB_DIR -n CA_agentV -c $CERTDB_DIR_PASSWORD ca-profile-enable $tmp_new_user_profile"
        rlRun "pki cert-request-profile-show $tmp_new_user_profile > $cert_request_profile_show_info"
        rlAssertGrep "Enrollment Template for Profile \"$tmp_new_user_profile\"" "$cert_request_profile_show_info"
        rlAssertGrep "Profile ID: $tmp_new_user_profile" "$cert_request_profile_show_info"
        rlPhaseEnd
	
	rlPhaseStartCleanup "pki cert-request-profile-show cleanup: Delete temp dir"
	rlRun "popd"
	rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    	rlPhaseEnd
}
