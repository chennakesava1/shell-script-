#!/bin/bash
export http_proxy=""
export https_proxy=""
admin="superadmin"
adminpass="Pass@1234"
# precisionuser="precision"
# precisionpass="Precision@123"
# precisionnewpass="Precision@1234"
host="neuro.default.philips.com"
user="nolisuser"
pass="Nolis@1234"
client_id=nolisapp

########################################
    ## Superadmin Password Change##
########################################

curl -X POST https://"${host}"/iam/api/v2.0/Credential/Reset -H 'content-type: application/json' \
-d '{
  "username": "superadmin",
  "password": "Pass@123",
  "newpassword": "Pass@1234",
  "securityQuestionWithAnswer": [
    {
      "questionText": "What is the color of your first car?",
      "securityAnswer": "test"
    },
    {
      "questionText": "What is your mother'\''s name?",
      "securityAnswer": "test"
    },
    {
      "questionText": "What is the name of your pet?",
      "securityAnswer": "test"
    }
  ]
}' -k

########################################
    ## token genarate ##
########################################

gen_token="$(curl -d "username="$admin"&password="$adminpass"&client_id=admin&grant_type=password" -X POST   https://"${host}":10003/api/v2.0/oauth2/token   -H 'cache-control: no-cache'   -H 'content-type: application/x-www-form-urlencoded' -k -m 10 -i)"
echo "${gen_token}"

token="$(echo "${gen_token}" |grep "access_token"  |cut -d '"' -f 4 )"

echo "${token}"

########################################
    ## Default ORG ID ##
########################################

# orgid="$( curl -X GET https://"${host}"/cdr/api/v2.0/stu3/Organization?_count=1000000 -k -H "authorization: Bearer ${token}" -H 'content-type: application/json;charset=UTF8' |grep id |cut -d '"' -f4 )"


# echo "${orgid}"



########################################
    ## Adding roles to Default ORG ##
########################################



curl -X PATCH  https://"${host}"/cdr/api/v2.0/stu3/ValueSet/phoenix-organization-roles \
  -H "authorization: Bearer ${token}" \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d '[{
      "op": "append",
        "path": "/compose/include",
        "value": {
                "system": "http://philips.phoenix.com/ems/InheritedRole/DEFAULT",
                "concept": [{
                        "code": "ROLE_NEUROLOGIST",
                        "_code": {
                                "extension": [{
                                        "url": "http://phoenix.philips.com/fhir/stu3/StructureDefinition/phoenixInheritedRole-extension",
                                        "valueString": ["ROLE_NOLIS_READ", "ROLE_NOLIS_PATIENT_WRITE", "ROLE_NOLIS_TASK_WRITE", "ROLE_NOLIS_LAUNCH", "ROLE_NOLIS_DEFAULT"]
                                }]
                        },
                        "display": "All roles are added"
                }]
        }
}, {
        "op": "append",
        "path": "/compose/include/0/concept",
        "value": {
                "code": "ROLE_NEUROLOGIST",
                "_code": {
                        "extension": [{
                                "url": "http://phoenix.philips.com/fhir/stu3/StructureDefinition/phoenixOrganizationRole-extension",
                                "valueReference": {
                                        "reference": "Organization/2f32eca6f5c24927ad6fe415f000c052"
                                }
                        }]
                },
                "display": "All roles are added"
        }
	}]'	-k

########################################
    ## Create a Practitioner ##
########################################

curl -X POST https://neuro.default.philips.com/cdr/api/v2.0/stu3/Practitioner \
          -H "authorization: Bearer ${token}" \
          -H 'cache-control: no-cache' \
          -H 'content-type: application/json' \
		  -d '{
	"meta": {
		"profile": ["http://phoenix.philips.com/fhir/stu3/StructureDefinition/PractitionerProfile", "http://phoenix.philips.com/fhir/stu3/StructureDefinition/PhoenixAccount"]
	},
	"resourceType": "Practitioner",
	"name": {
		"given": ["nolisuser"],
		"family": ""
	},
	"address": [{
		"use": "work",
		"type": "physical",
		"line": [""],
		"country": "",
		"state": "",
		"city": "",
		"postalCode": ""
	}],
	"credentials": [{
		"type": "password",
		"password": "Nolis@123"
	}],
	"accountName": "nolisuser",
	"enabled": true,
	"locked": false
}' -k

########################################
    ## Practitioner password reset ##
########################################

curl -X POST https://neuro.default.philips.com/iam/api/v2.0/Credential/Reset \
		  -H 'content-type: application/json' \
		  -d '{
	"username": "nolisuser",
	"action": "RESET",
	"password": "Nolis@123",
	"newpassword": "Nolis@1234",
	"securityQuestionWithAnswer": [{
		"questionText": "What is the color of your first car?",
		"securityAnswer": "test"
	}, {
		"questionText": "What is your mother'\''s name?",
		"securityAnswer": "test"
	}, {
		"questionText": "What is the name of your pet?",
		"securityAnswer": "test"
	}]
}' -k


########################################
    ## Practitioner TOKEN ##
########################################

ngen_token="$(curl -d "username=nolisuser&password=Nolis@1234&client_id=admin&grant_type=password" -X POST   https://"${host}":10003/api/v2.0/oauth2/token   -H 'cache-control: no-cache'   -H 'content-type: application/x-www-form-urlencoded' -k -m 10 -i)"
echo "${ngen_token}"


ntoken="$(echo "${ngen_token}" |grep "access_token"  |cut -d '"' -f 4 )"



echo "${ntoken}"

########################################
    ## Practitioner ID ##
########################################

practitionerinfo="$( curl -X GET https://${host}:10003/api/v2.0/openid/userinfo \
           -H "authorization: Bearer ${ntoken}" \
           -H 'cache-control: no-cache' \
           -H 'content-type: application/json' \
           -H 'Audit-Log-Required: false' -k )"

practitionerID="$(echo "${practitionerinfo}" | tr , '\n' | grep "fhir_id" | cut -d '"' -f4 )"

########################################
    ## Adding ORG & Roles Practitioner ##
########################################
		  
curl -X POST https://neuro.default.philips.com/cdr/api/v2.0/stu3/PractitionerRole \
          -H "authorization: Bearer ${token}" \
          -H 'cache-control: no-cache' \
          -H 'content-type: application/json' \
          -d "{
	\"meta\": {
		\"profile\": [\"http://phoenix.philips.com/fhir/stu3/StructureDefinition/PhoenixRoleMapping\"]
	},
	\"code\": [{
		\"coding\": [{
			\"code\": \"ROLE_NEUROLOGIST\",
			\"system\": \"http://philips.phoenix.com/ems/OrganizationRoles\"
		}]
	}],
	\"active\": true,
	\"organization\": {
		\"reference\": \"Organization/2f32eca6f5c24927ad6fe415f000c052\"
	},
	\"practitioner\": {
		\"reference\": \"Practitioner/"${practitionerID}"\"
	},
	\"resourceType\": \"PractitionerRole\"
}" -k

########################################
    ## Creating Plan / activity Definition & Value sets & Medication ##
########################################






gen_token="$(curl -d "username="$user"&password="$pass"&client_id="$client_id"&grant_type=password&scope=profile offline_access" -X POST   https://"${host}":443/iam/api/v2.0/oauth2/token   -H 'cache-control: no-cache'   -H 'content-type: application/x-www-form-urlencoded'   -H 'postman-token: 0b6e6397-22e7-09b8-b5b1-d0e33b866229' -k -m 10 -i)"



Validation_Credentials="$(echo "${gen_token}" |grep -ic "Bad credentials")"
Validation_account_locked="$(echo "${gen_token}" |grep -ic "User account is locked")"
Validation_Reset_password="$(echo "${gen_token}" |grep -ic "Reset password")"
Validation_nolisapp="$(echo "${gen_token}" |grep -ic "Client with id nolisapp was not found")"
Validation_access_token="$(echo "${gen_token}" |grep -ic "access_token")"
PlanDefinition_validation="$(curl -X GET \
  https://"${host}"/cdr/api/v2.0/stu3/PlanDefinition \
  -H "authorization: Bearer ${token}" \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' --insecure | grep total |cut -d ':' -f 2|rev |cut -c 2- )"
  
echo "${PlanDefinition_validation}"
if [ $PlanDefinition_validation == 0 ] 
  then
   echo "PlanDefinition total values 0"
   else
   echo "PlanDefinition total values ${PlanDefinition_validation}"
fi
#echo "${gen_token}"
#echo "${Validation_Credentials}"
#echo "${cre_validation_count}" "conunt OK"




token="$(echo "${gen_token}" |grep "token"  |cut -d '"' -f 4 )"



Activity_Definition ()
{
review_id="$(curl -X POST \
  https://"${host}"/cdr/api/v2.0/stu3/ActivityDefinition \
  -H "authorization: Bearer ${token}" \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d '{

	"resourceType": "ActivityDefinition",

	"url": "http://example.org/ActivityDefinition/ReviewEEG",
	"name": "Review EEG",
	"status": "active",
	"description": "This Activity is for Review EEG for Patient",
	"purpose": "This For ReviewEEG",
	"topic": [{
		"coding": [{
			"system": "http://snomed.info/sct",
			"code": "292003",
			"display": "EEG finding"
		}],
		"text": "EEG finding"
	}],
	"relatedArtifact": [{
		"type": "documentation",
		"display": "This Activity is for Review EEG for Patient."
	}],
	"kind": "ProcedureRequest",
	"code": {
		"text": "EEG Review"
	},
	"participant": [{
		"type": "practitioner"
	}]
}' --insecure | head -2 | tail -1 | cut -d '"' -f4  )"

acquire_id="$(curl -X POST \
  https://"${host}"/cdr/api/v2.0/stu3/ActivityDefinition \
  -H "authorization: Bearer ${token}" \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d '{
    "resourceType": "ActivityDefinition",
	"url": "http://example.org/ActivityDefinition/AcquireEEG",
	"name": "Acquire EEG",
	"status": "active",
	"description": "This Activity is for Acquire EEG for Patient",
	"purpose": "This For AcquireEEG",
	"topic": [{
		"coding": [{
			"system": "http://snomed.info/sct",
			"code": "292003",
			"display": "EEG finding"
		}],
		"text": "EEG finding"
	}],
	"relatedArtifact": [{
		"type": "documentation",
		"display": "This Activity is for Acquire EEG for Patient."
	}],
	"kind": "ProcedureRequest",
	"code": {
		"text": "Intracerebral electroencephalogram"
	},
	"participant": [{
		"type": "practitioner"
	}]
}' --insecure | head -2 | tail -1 | cut -d '"' -f4 )"

}

Create_PlanDefinition_Follow_Up ()
{
echo "{

                \"title\": \"This example illustrates relationships between actions.\",
                \"topic\": [
                    {
                        \"text\": \"EEG finding\",
                        \"coding\": [
                            {
                                \"code\": \"185389009\",
                                \"system\": \"http://snomed.info/sct\",
                                \"display\": \"Follow Up\"
                            }
                        ]
                    }
                ],
                \"action\": [
                    {
                        \"action\": [
                            {
                                \"id\": \"ReviewEEG\",
                                \"title\": \"ActivityDefinition 2\",
                                \"definition\": {
                                    \"reference\": \"#"${review_id}"\"
                                }
                            }
                        ],
                        \"groupingBehavior\": \"logical-group\",
                        \"selectionBehavior\": \"all\"
                    }
                ],
                \"status\": \"draft\",
                \"contained\": [
                    {
                        \"id\": \""${review_id}"\",
                        \"kind\": \"Task\",
                        \"name\": \"Review EEG\",
                        \"status\": \"active\",
                        \"resourceType\": \"ActivityDefinition\",
                        \"productCodeableConcept\": {
                            \"text\": \"Review EEG\"
                        }
                    }
                ],
                \"resourceType\": \"PlanDefinition\"

        }" > PlanDefinition_Follow_Up.json

}

Plan_Definition_FollowUP ()
{
curl -X POST \
  https://"${host}"/cdr/api/v2.0/stu3/PlanDefinition \
  -H "authorization: Bearer ${token}" \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d "@PlanDefinition_Follow_Up.json" --insecure > PlanD_FollowUP_out.json
}

Create_PlanDefinition_finding ()
{
echo "{

                \"title\": \"This example illustrates relationships between actions.\",
                \"topic\": [
                    {
                        \"text\": \"EEG finding\",
                        \"coding\": [
                            {
                                \"code\": \"292003\",
                                \"system\": \"http://snomed.info/sct\",
                                \"display\": \"EEG finding\"
                            }
                        ]
                    }
                ],
                \"action\": [
                    {
                        \"action\": [
                            {
                                \"id\": \"AquireEEG\",
                                \"title\": \"ActivityDefinition 1\",
                                \"definition\": {
                                    \"reference\": \"#"${acquire_id}"\"
                                }
                            },
                            {
                                \"id\": \"ReviewEEG\",
                                \"title\": \"ActivityDefinition 2\",
                                \"definition\": {
                                    \"reference\": \"#"${review_id}"\"
                                }
                            }
                        ],
                        \"groupingBehavior\": \"logical-group\",
                        \"selectionBehavior\": \"all\"
                    }
                ],
                \"status\": \"draft\",
                \"contained\": [
                    {
                        \"id\": \""${acquire_id}"\",
                        \"kind\": \"Task\",
                        \"name\": \"Acquire EEG\",
                        \"status\": \"active\",
                        \"resourceType\": \"ActivityDefinition\",
                        \"productCodeableConcept\": {
                            \"text\": \"Acquire EEG\"
                        }
                    },
                    {
                        \"id\": \""${review_id}"\",
                        \"kind\": \"Task\",
                        \"name\": \"Review EEG\",
                        \"status\": \"active\",
                        \"resourceType\": \"ActivityDefinition\",
                        \"productCodeableConcept\": {
                            \"text\": \"Review EEG\"
                        }
                    }
                ],
                \"resourceType\": \"PlanDefinition\"
            }" > PlanDefinition_finding.json
}

Plan_Definition_Finding()
{
curl -X POST \
  https://"${host}"/cdr/api/v2.0/stu3/PlanDefinition \
  -H "authorization: Bearer ${token}" \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d "@PlanDefinition_finding.json" --insecure > PlnaD_Finding_out.json
}

ValueSet_studytype()
{
curl -X POST \
  http://"${host}":8089/api/v2.0/stu3/ValueSet \
  -H "authorization: Bearer ${token}" \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d '{   
   "resourceType":"ValueSet",
   "url": "http://hl7.org/fhir/ValueSet/condition-code",
   "name":"StudyType",
   "compose":{  
      "include":[  
         {  
            "system":"https://www.hl7.org/fhir/valueset-condition-code.html",
            "concept":[  
               {  
                  "code":"252721009",
                  "display":"Routine EEG"
               },
               {  
                  "code":"252735006",
                  "display":"Extended EEG"
               },
               {  
                  "code":"462373009",
                  "display":"Long-Term Monitoring"
               },
               {  
                  "code":"385432009",
                  "display":"N/A"
               }
            ]
         }
      ]
   },
  "status":"draft"
}' > valueset_studytype.json 

}


valueset_visitreason ()
{
curl -X POST \
  http://"${host}":8089/api/v2.0/stu3/ValueSet \
  -H "authorization: Bearer ${token}" \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d '{  
   "resourceType":"ValueSet",
   "url": "http://hl7.org/fhir/ValueSet/condition-code",
   "name":"VisitReason",
   "compose":{  
      "include":[  
         {  
            "system":"https://www.hl7.org/fhir/valueset-condition-code.html",
            "concept":[  
               {  
                  "code":"77765009",
                  "display":"Epilepsy rule out"
               },
               {  
                  "code":"360152008",
                  "display":"Monitoring"
               },
               {  
                  "code":"734163000",
                  "display":"Discuss care plan"
               }
            ]
         }
      ]
   },
  "status":"draft"
}' > valueset_visitreason.json
}

valueset_visittype ()
{
curl -X POST \
  http://"${host}":8089/api/v2.0/stu3/ValueSet \
  -H "authorization: Bearer ${token}" \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d '{  
   "resourceType":"ValueSet",
   "url": "http://hl7.org/fhir/ValueSet/condition-code",
   "name":"VisitType",
   "compose":{  
      "include":[  
         {  
            "system":"https://www.hl7.org/fhir/valueset-condition-code.html",
            "concept":[  
               {  
                  "code":"292003",
                  "display":"EEG study"
               },
               {  
                  "code":"185389009",
                  "display":"Follow up"
               }
            ]
         }
      ]
   },
  "status":"draft"
}' > valueset_visittype.json
}
valueset_SensorTypes ()
{
curl -X POST \
  http://"${host}":8089/api/v2.0/stu3/ValueSet \
  -H "authorization: Bearer ${token}" \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d '{

	"url": "http://hl7.org/fhir/ValueSet/condition-code",
	"name": "SensorTypes",
	"status": "draft",
	"compose": {
		"include": [{
			"system": "https://www.hl7.org/fhir/valueset-condition-code.html",
			"concept": [{
					"code": "32",
					"display": "Low Desity Sensors"
				},
				{
					"code": "64",
					"display": "Medium Desity Sensors"
				},
				{
					"code": "128",
					"display": "Medium Desity Sensors"
				},
				{
					"code": "256",
					"display": "High Desity Sensors"
				}
			]
		}]
	},
	"resourceType": "ValueSet"
}' > valueset_SensorTypes.json
}

medication_list ()
{
curl -X POST \
  http://"${host}":8091/api/medications/import \
  -H "authorization: Bearer ${token}" \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/xml' \
  -d '<?xml version="1.0" encoding="UTF-8" ?>
<Medications>
    <Medication id="1">
        <Generic_DRUG_Name>DIAMOX (acetazolamide)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>372709008</SNOMED_CT_Codes>
    </Medication>
    <Medication id="2">
        <Generic_DRUG_Name>ACTH (adrenocorticotropic hormone)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>40789008</SNOMED_CT_Codes>
    </Medication>
    <Medication id="3">
        <Generic_DRUG_Name>alcohol (ETOH)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>419442005</SNOMED_CT_Codes>
    </Medication>
    <Medication id="4">
        <Generic_DRUG_Name>ALDOMET (methyldopa)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>373542000</SNOMED_CT_Codes>
    </Medication>
    <Medication id="5">
        <Generic_DRUG_Name>ELAVIL (amitriptyline HCL)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>48384000</SNOMED_CT_Codes>
    </Medication>
    <Medication id="6">
        <Generic_DRUG_Name>AUGMENTIN (amoxicillin trihydrate)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>96068000</SNOMED_CT_Codes>
    </Medication>
    <Medication id="7">
        <Generic_DRUG_Name>AMYTAL (sodium amytal)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>387343004</SNOMED_CT_Codes>
    </Medication>
    <Medication id="8">
        <Generic_DRUG_Name>ASPIRIN (ASA) (acetylsalicylic acid)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>387458008</SNOMED_CT_Codes>
    </Medication>
    <Medication id="9">
        <Generic_DRUG_Name>ATTARAX (hydroxyzine)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>372856003</SNOMED_CT_Codes>
    </Medication>
    <Medication id="10">
        <Generic_DRUG_Name>BENADRYL (diphenhydramine HCL)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>19510001</SNOMED_CT_Codes>
    </Medication>
    <Medication id="11">
        <Generic_DRUG_Name>BREVITAL (methohexital)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>373488009</SNOMED_CT_Codes>
    </Medication>
    <Medication id="12">
        <Generic_DRUG_Name>CAFATINE, CAFERGOT, CARDTRATE, ERCAF, ERGOMAR, WIGRAINE (ergotamine)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>395975005</SNOMED_CT_Codes>
    </Medication>
    <Medication id="13">
        <Generic_DRUG_Name>(carbamazepine) TEGRETOL</Generic_DRUG_Name>
        <SNOMED_CT_Codes>387222003</SNOMED_CT_Codes>
    </Medication>
    <Medication id="14">
        <Generic_DRUG_Name>(chloral hydrate) AQUA-CHLORAL SUPPRETTES</Generic_DRUG_Name>
        <SNOMED_CT_Codes>273948005</SNOMED_CT_Codes>
    </Medication>
    <Medication id="15">
        <Generic_DRUG_Name>(clonazepam) KLONOPIN</Generic_DRUG_Name>
        <SNOMED_CT_Codes>387383007</SNOMED_CT_Codes>
    </Medication>
    <Medication id="16">
        <Generic_DRUG_Name>(chlordiazepoxide HCL) LIBRIUM</Generic_DRUG_Name>
        <SNOMED_CT_Codes>40601003</SNOMED_CT_Codes>
    </Medication>
    <Medication id="17">
        <Generic_DRUG_Name>(chlorpromazine) THORAZINE</Generic_DRUG_Name>
        <SNOMED_CT_Codes>387258005</SNOMED_CT_Codes>
    </Medication>
    <Medication id="18">
        <Generic_DRUG_Name>(codeine)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>387494007</SNOMED_CT_Codes>
    </Medication>
    <Medication id="19">
        <Generic_DRUG_Name>COUMADIN (warfari sodium)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>63167009</SNOMED_CT_Codes>
    </Medication>
    <Medication id="20">
        <Generic_DRUG_Name>DALMANE (flurazepam HCL)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>387109000</SNOMED_CT_Codes>
    </Medication>
    <Medication id="21">
        <Generic_DRUG_Name>DARVON (propoxyphene HCL)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>56297001</SNOMED_CT_Codes>
    </Medication>
    <Medication id="22">
        <Generic_DRUG_Name>DECADRON, BALDEX, DALALONE, DEXACORT, DEXASONE, MAXIDEX, SOLUREX (dexamethasone)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>372584003</SNOMED_CT_Codes>
    </Medication>
    <Medication id="23">
        <Generic_DRUG_Name>DEMORAL (meperidine)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>387298007</SNOMED_CT_Codes>
    </Medication>
    <Medication id="24">
        <Generic_DRUG_Name>DEPACON, DEPAKENE, DEPAKOTE (valproic acid)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>387080000</SNOMED_CT_Codes>
    </Medication>
    <Medication id="25">
        <Generic_DRUG_Name>DHE-45 (dihydroergotamine)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>387267005</SNOMED_CT_Codes>
    </Medication>
    <Medication id="26">
        <Generic_DRUG_Name>(diazepam) VALIUM</Generic_DRUG_Name>
        <SNOMED_CT_Codes>387264003</SNOMED_CT_Codes>
    </Medication>
    <Medication id="27">
        <Generic_DRUG_Name>DILANTIN (phenytoin)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>387220006</SNOMED_CT_Codes>
    </Medication>
    <Medication id="28">
        <Generic_DRUG_Name>(doxepin HCL) SINEQUAN</Generic_DRUG_Name>
        <SNOMED_CT_Codes>85037008</SNOMED_CT_Codes>
    </Medication>
    <Medication id="29">
        <Generic_DRUG_Name>(ethosuximide) ZARONTIN</Generic_DRUG_Name>
        <SNOMED_CT_Codes>387244008</SNOMED_CT_Codes>
    </Medication>
    <Medication id="30">
        <Generic_DRUG_Name>(felbamate) FELBATOL</Generic_DRUG_Name>
        <SNOMED_CT_Codes>96194006</SNOMED_CT_Codes>
    </Medication>
    <Medication id="31">
        <Generic_DRUG_Name>FIORINAL, FIORGEN PF, ISOLLYL IMPROVED, LANORINAL (aspirin, caffeine and butalbital)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>A-387458008 C-255641001 B-387563005</SNOMED_CT_Codes>
    </Medication>
    <Medication id="32">
        <Generic_DRUG_Name>FLUORTHANE (halothane)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>387351001</SNOMED_CT_Codes>
    </Medication>
    <Medication id="33">
        <Generic_DRUG_Name>(fluoxetine HCL) PROZAC</Generic_DRUG_Name>
        <SNOMED_CT_Codes>372767007</SNOMED_CT_Codes>
    </Medication>
    <Medication id="34">
        <Generic_DRUG_Name>(gabapentin) NEURONTIN</Generic_DRUG_Name>
        <SNOMED_CT_Codes>386845007</SNOMED_CT_Codes>
    </Medication>
    <Medication id="35">
        <Generic_DRUG_Name>HALDOL (haloperidol)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>386837002</SNOMED_CT_Codes>
    </Medication>
    <Medication id="36">
        <Generic_DRUG_Name>(halothane) FLUOTHANE</Generic_DRUG_Name>
        <SNOMED_CT_Codes>387351001</SNOMED_CT_Codes>
    </Medication>
    <Medication id="37">
        <Generic_DRUG_Name>(heroin)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>387341002</SNOMED_CT_Codes>
    </Medication>
    <Medication id="38">
        <Generic_DRUG_Name>INDERAL (propranolol HCL)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>65088001</SNOMED_CT_Codes>
    </Medication>
    <Medication id="39">
        <Generic_DRUG_Name>LAMICTAL (lamotrigine)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>387562000</SNOMED_CT_Codes>
    </Medication>
    <Medication id="40">
        <Generic_DRUG_Name>(lithium)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>85899009</SNOMED_CT_Codes>
    </Medication>
    <Medication id="41">
        <Generic_DRUG_Name>LSD (lysergic acid diethylamide)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>15698006</SNOMED_CT_Codes>
    </Medication>
    <Medication id="42">
        <Generic_DRUG_Name>LUMINAL (phenobarbital)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>373505007</SNOMED_CT_Codes>
    </Medication>
    <Medication id="43">
        <Generic_DRUG_Name>MEBARAL (mephobarbital)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>387252006</SNOMED_CT_Codes>
    </Medication>
    <Medication id="44">
        <Generic_DRUG_Name>MESANTOIN (mephenytoin)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>28344001</SNOMED_CT_Codes>
    </Medication>
    <Medication id="45">
        <Generic_DRUG_Name>METRAZOL (pentylenetetrazol)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>19901000</SNOMED_CT_Codes>
    </Medication>
    <Medication id="46">
        <Generic_DRUG_Name>(methylphenidate) RITALIN</Generic_DRUG_Name>
        <SNOMED_CT_Codes>373337007</SNOMED_CT_Codes>
    </Medication>
    <Medication id="47">
        <Generic_DRUG_Name>(morhpine)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>373529000</SNOMED_CT_Codes>
    </Medication>
    <Medication id="48">
        <Generic_DRUG_Name>MYSOLINE (primidone)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>387256009</SNOMED_CT_Codes>
    </Medication>
    <Medication id="49">
        <Generic_DRUG_Name>PARADIONE (paramethadione)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>61357000</SNOMED_CT_Codes>
    </Medication>
    <Medication id="50">
        <Generic_DRUG_Name>PARAL (paraldehyde)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>387190006</SNOMED_CT_Codes>
    </Medication>
    <Medication id="51">
        <Generic_DRUG_Name>PCP (phencyclidine)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>9721008</SNOMED_CT_Codes>
    </Medication>
    <Medication id="52">
        <Generic_DRUG_Name>PENTOTHAL (thiopental sodium)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>387448009</SNOMED_CT_Codes>
    </Medication>
    <Medication id="53">
        <Generic_DRUG_Name>(pentazocine lactate) TALWIN</Generic_DRUG_Name>
        <SNOMED_CT_Codes>71533000</SNOMED_CT_Codes>
    </Medication>
    <Medication id="54">
        <Generic_DRUG_Name>PHENURONE (phenacemide)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>18712002</SNOMED_CT_Codes>
    </Medication>
    <Medication id="55">
        <Generic_DRUG_Name>(prednisone) PREDNISOL, PRELONE</Generic_DRUG_Name>
        <SNOMED_CT_Codes>116602009</SNOMED_CT_Codes>
    </Medication>
    <Medication id="56">
        <Generic_DRUG_Name>SECONAL (secobarbital sodium)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>372737001</SNOMED_CT_Codes>
    </Medication>
    <Medication id="57">
        <Generic_DRUG_Name>STELAZINE (trifluoperazine HCL)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>50754002</SNOMED_CT_Codes>
    </Medication>
    <Medication id="58">
        <Generic_DRUG_Name>TRIDIONE (trimethadione)</Generic_DRUG_Name>
        <SNOMED_CT_Codes>70732003</SNOMED_CT_Codes>
    </Medication>
</Medications>
' > medication_list.json
}
# ######

# curl -X DELETE \
  # http://"${host}":8089/api/v2.0/stu3/ValueSet/70bb28cbe2dd4544a9701a4dbc247d97 \
  # -H "authorization: Bearer ${token}"
  
 # ######
if [ $Validation_access_token -eq 1 ] && [ $PlanDefinition_validation == 0 ]
then
    echo "Token Generated!" 
	  
	 Activity_Definition
	 sleep 2
	 Create_PlanDefinition_Follow_Up
	 Plan_Definition_FollowUP
	 sleep 2
	 Create_PlanDefinition_finding
	 Plan_Definition_Finding
	 sleep 2
	 ValueSet_studytype
	 sleep 2
	 valueset_visitreason
	 sleep 2
	 valueset_visittype
	 sleep 2
	 valueset_SensorTypes
	 sleep 2
	 medication_list
	

elif [ $Validation_Credentials -eq 1 ]
then
    echo "User name and Password is wrong! Please enter the Username and passowrd with case sensitive"
	
elif [ $Validation_account_locked -eq 1 ]
then
    echo "Given User account is locked! login as a superadmin then unlock the account"
 
elif [ $Validation_Reset_password -eq 1 ]
then
    echo "The specified account is being used to login for the first time. Reset password is necessary"
	
elif [ $Validation_nolisapp -eq 1 ]
then
    echo "Client with id nolisapp was not found! Check Nolis application is running or not!"
	
elif [ $PlanDefinition_validation == 2 ]
then 
    echo " PlanDefinition already exists! Hence, this script will not be executed again!"
else

    echo "Onboard script execution not completed successfully. Please contact System Administrator!!!!!! "
	echo  "${gen_token}"
	
fi


