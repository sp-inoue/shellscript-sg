# shellscript-sg
### ip_address_change.sh
Amazon Q Developer in chat applicationsでの使用想定<br>
セキュリティグループに設定された該当のIPアドレスを変更するシェルスクリプト  
## 使用方法
Amazon Q Developer in chat applicationsと紐づけをしたTeamsのチャネルにて、@Amazon Qにメンションを付け、以下のコマンドを実行する

``` bash
ssm send-command --targets Key=InstanceIds,Values=インスタンスID --document-name 作成したドキュメント名 --cloud-watch-output-config CloudWatchOutputEnabled=true,CloudWatchLogGroupName="ログを出力するファイル" --parameters OLDIP=変更前IP,NEWIP=変更後IP --region ap-northeast-1
```
### 各種値
Values=インスタンスID：このshファイルが設置されているEC2インスタンスID<br>
--document-name：使用したいSSMドキュメントの名前<br>
CloudWatchLogGroupName：実行履歴を格納したいログファイルの名前<br>
OLDIP：変更前のIP<br>
NEWIP：変更後のIP<br>

#### 参考：https://github.com/Kobayashi-Riku0226/shellscript