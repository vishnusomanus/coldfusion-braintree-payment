## ColdFusion Braintree payment application

1. Move lib/braintree-java-3.23.0 to coldfusion lib folder


2. Add values in Braintree.cfc

```
  <cfset application.braintreeEnvironment = "sandbox">
  <cfset application.braintreeMerchantId = "xxxxxxx">
  <cfset application.braintreePublicKey = "xxxxxxx">
  <cfset application.braintreePrivateKey = "xxxxxx">

```

3. Start Server

```
start cfengine=adobe@2021 port=8888

```


All functions will not works. I have tested only 3 functions.

* generateClientToken()
* processPayment()
* getTransactionDetails()