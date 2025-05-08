#!/bin/bash

# インバウンドルールに該当のIPアドレスが設定されてるセキュリティグループのIDを取得
sg_ids=$(aws ec2 describe-security-groups --filters Name=ip-permission.cidr,Values=$1 --query SecurityGroups[].GroupId)

# 0.0.0.0/0 と会社IPの場合は処理をストップ
if [ "$1" == "0.0.0.0/32" ] || [ "$1" == "会社IP1/32" ] || [ "$1" == "会社IP2/32" ] || [ "$2" == "0.0.0.0/0" ] || [ "$2" == "会社IP1/32" ] || [ "$2" == "会社IP2/32" ]; then
    echo "ERROR: この設定は許可されていません。"
    exit 1
fi

# 変更前のIPが設定されているか確認
# なかったら処理をストップ
if [ "$sg_ids" == "[]" ]; then
    echo "ERROR: 変更前IPアドレスが現在の設定に存在しません。"
    exit 2
else
    # あったら取得したセキュリティグループを表示
    echo -e "対象のセキュリティグループ\n$sg_ids\n"
fi

#セキュリティグループIDの数だけ処理を行うためfor文でループさせる
for sg_id in $(echo $sg_ids | jq '.[]' | sed -E 's/[\"]//g'); do

    echo -e $sg_id
    echo -e "\n$sg_id を変更中"
    #セキュリティグループに設定されているルールを取得
    sg_rules=$(aws ec2 describe-security-group-rules --filters Name=group-id,Values=$sg_id --query SecurityGroupRules)

    #セキュリティグループに設定されているルールの数だけ処理を行うためfor文でループさせる
    for sg_rule_id in $(echo $sg_rules | jq '.[].SecurityGroupRuleId'); do

        #セキュリティグループルールに設定されているIPアドレスを取得
        CidrIpv4=$(aws ec2 describe-security-group-rules --filters Name=security-group-rule-id,Values=$sg_rule_id | jq '.SecurityGroupRules[].CidrIpv4' | sed -E 's/[\"]//g')

        #インバウンドルール、アウトバウンドルールか確認するために実行
        sg_rule_type=$(aws ec2 describe-security-group-rules --filters Name=security-group-rule-id,Values=$sg_rule_id | jq '.SecurityGroupRules[].IsEgress')

        #Descriptionを取得
        sg_rule_description=$(aws ec2 describe-security-group-rules --filters Name=security-group-rule-id,Values=$sg_rule_id | jq '.SecurityGroupRules[].Description')

        #該当のIPアドレスであること、インバウンドルールであることをチェックする
        if [ $1 = $CidrIpv4 ] && [ false = $sg_rule_type ]; then

            #セキュリティグループルールに設定するプロトコル、ポート番号を取得
            IpProtocol=$(aws ec2 describe-security-group-rules --filters Name=security-group-rule-id,Values=$sg_rule_id | jq '.SecurityGroupRules[].IpProtocol' | sed -E 's/[\"]//g')
            FromPort=$(aws ec2 describe-security-group-rules --filters Name=security-group-rule-id,Values=$sg_rule_id | jq '.SecurityGroupRules[].FromPort')
            ToPort=$(aws ec2 describe-security-group-rules --filters Name=security-group-rule-id,Values=$sg_rule_id | jq '.SecurityGroupRules[].ToPort')

            #IPアドレスの変更を実行
            aws ec2 modify-security-group-rules --group-id $sg_id --security-group-rules SecurityGroupRuleId=$sg_rule_id,SecurityGroupRule={"IpProtocol=$IpProtocol,FromPort=$FromPort,ToPort=$ToPort,CidrIpv4=$2,Description=$sg_rule_description"}
        fi
    done
done

echo -e "\nIPアドレスの変更が完了しました"
