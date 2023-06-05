<cfcomponent>
  <cfset application.braintreeEnvironment = "sandbox">
  <cfset application.braintreeMerchantId = "tm7vfsxx3jpd2zmz">
  <cfset application.braintreePublicKey = "qjfj9b6g2ny2hzsq">
  <cfset application.braintreePrivateKey = "d61a3b276e848cee4a7bf94658786bea">

  <cfset gateway = CreateObject("java", "com.braintreegateway.BraintreeGateway").init(
    application.braintreeEnvironment,
    application.braintreeMerchantId,
    application.braintreePublicKey,
    application.braintreePrivateKey
  )>

  <!--- Generate a client token for the frontend --->
  <cffunction name="generateClientToken" access="public" output="false">
    <cfset clientToken = ''>
    <cftry>
      <cfset clientToken = gateway.clientToken().generate()>
      <cfcatch>
        <cfset clientToken = ''>
      </cfcatch>
    </cftry>
    <cfreturn clientToken>
  </cffunction>

  <!--- Process a payment transaction --->
  <cffunction name="processPayment" access="public" output="false">
    <cfargument name="nonce" type="string" required="true">
    <cfargument name="amount" type="string" required="true">
    
    <cfset var response = {
      "success": false,
      "message": "",
      "transactionId": "",
      "status": "",
      "amount": "",
      "currency": ""
    }>
    
    <cftry>
      <cfset bigDecimal = createObject("java", "java.math.BigDecimal").init(arguments.amount)>
      <cfset req = CreateObject("java", "com.braintreegateway.TransactionRequest").amount(bigDecimal)
        .paymentMethodNonce(arguments.nonce).options().submitForSettlement(true).done()>
      <cfset result = gateway.transaction().sale(req)>
      <cfif result.isSuccess()>
        <cfset response.success = true>
        <cfset response.message = "Payment successful.">
        <cfset transaction = result.getTarget()>
        <cfset response.transactionId = transaction.getId()>
        <cfset response.status = transaction.getStatus().name()>
        <cfset response.amount = transaction.getAmount()>
        <cfset response.currency = transaction.getCurrencyIsoCode()>
        <!--- Add more payment details as needed --->
      <cfelse>
        <cfset response.message = result.getMessage()>
      </cfif>
      <cfcatch type="any">
        <cfset response.message = cfcatch.message>
      </cfcatch>
    </cftry>
    
    <cfreturn response>
  </cffunction>
  


  <cffunction name="getTransactionDetails" access="public" output="false">
    <cfargument name="transactionId" type="string" required="true">
    <cfset transactionDetails = {}>
    <cftry>
      <cfset transaction = gateway.transaction().find(arguments.transactionId)>
      <cfset transactionDetails.transactionId = transaction.getId()>
      <cfset transactionDetails.status = transaction.getStatus().name()>
      <cfset transactionDetails.amount = transaction.getAmount()>
      <cfset transactionDetails.currency = transaction.getCurrencyIsoCode()>
      <cfset transactionDetails.paymentInstrumentType = transaction.getPaymentInstrumentType()>
      <cfset transactionDetails.processorAuthorizationCode = transaction.getProcessorAuthorizationCode()>
      <cfset transactionDetails.processorResponseCode = transaction.getProcessorResponseCode()>
      <cfset transactionDetails.processorResponseText = transaction.getProcessorResponseText()>
    
      <cfcatch>
        <cfset transactionDetails = {}>
      </cfcatch>
    </cftry>
    <cfreturn transactionDetails>
  </cffunction>

  <!--- Refund a transaction by transaction ID --->
  <cffunction name="refundTransaction" access="public" output="false">
    <cfargument name="transactionId" type="string" required="true">
    <cfset success = false>
    <cftry>
      <cfset result = gateway.transaction().refund(arguments.transactionId)>
      <cfif result.isSuccess()>
        <cfset success = true>
      </cfif>
      <cfcatch>
        <cfset success = false>
      </cfcatch>
    </cftry>
    <cfreturn success>
  </cffunction>

  <cffunction name="searchTransactions" access="public" output="false">
    <cfargument name="status" type="string" required="false">
    <cfargument name="startDate" type="date" required="false">
    <cfargument name="endDate" type="date" required="false">
    <cfargument name="customerId" type="string" required="false">
    
    <cfset transactionList = []>
    <cftry>
      <cfset searchRequest = gateway.transaction().search()>
      
      <!--- Set search criteria based on input arguments --->
      <cfif arguments.status neq "">
        <cfset searchRequest.status().is(arguments.status)>
      </cfif>
      <cfif arguments.startDate neq "" and arguments.endDate neq "">
        <cfset searchRequest.createdAt().between(arguments.startDate, arguments.endDate)>
      </cfif>
      <cfif arguments.customerId neq "">
        <cfset searchRequest.customerId().is(arguments.customerId)>
      </cfif>
      
      <!--- Execute the search and retrieve the results --->
      <cfset transactionResult = searchRequest.results()>
      <cfloop from="1" to="#transactionResult.size()#" index="i">
        <cfset transactionList.append(transactionResult.get(i))>
      </cfloop>
      
      <cfcatch>
        <cfset transactionList = []>
      </cfcatch>
    </cftry>
    
    <cfreturn transactionList>
  </cffunction>

  <cffunction name="createSubscription" access="public" output="false">
    <cfargument name="customerId" type="string" required="true">
    <cfargument name="planId" type="string" required="true">
    <cfargument name="subscriptionData" type="struct" required="true">
    
    <cfset subscription = {}>
    <cftry>
      <cfset request = CreateObject("java", "com.braintreegateway.SubscriptionRequest")>
      
      <!--- Set subscription details based on input arguments --->
      <cfset request.customerId(arguments.customerId)>
      <cfset request.planId(arguments.planId)>
      <cfloop collection="#arguments.subscriptionData#" item="key">
        <cfset request[key] = arguments.subscriptionData[key]>
      </cfloop>
      
      <!--- Create the subscription --->
      <cfset result = gateway.subscription().create(request)>
      
      <cfset subscription.subscriptionId = result.getSubscription().getId()>
      <cfset subscription.status = result.getSubscription().getStatus().name()>
      <!--- Add more details as needed --->
      
      <cfcatch>
        <cfset subscription = {}>
      </cfcatch>
    </cftry>
    
    <cfreturn subscription>
  </cffunction>

  <cffunction name="getSubscriptionDetails" access="public" output="false">
    <cfargument name="subscriptionId" type="string" required="true">
    
    <cfset subscriptionDetails = {}>
    <cftry>
      
      <!--- Retrieve the subscription details by ID --->
      <cfset subscription = gateway.subscription().find(arguments.subscriptionId)>
      
      <cfset subscriptionDetails.subscriptionId = subscription.getId()>
      <cfset subscriptionDetails.status = subscription.getStatus().name()>
      <!--- Add more details as needed --->
      
      <cfcatch>
        <cfset subscriptionDetails = {}>
      </cfcatch>
    </cftry>
    
    <cfreturn subscriptionDetails>
  </cffunction>
  
  <cffunction name="cancelSubscription" access="public" output="false">
    <cfargument name="subscriptionId" type="string" required="true">
    
    <cfset success = false>
    <cftry>
      <cfset result = gateway.subscription().cancel(arguments.subscriptionId)>
      
      <cfif result.isSuccess()>
        <cfset success = true>
      </cfif>
      
      <cfcatch>
        <cfset success = false>
      </cfcatch>
    </cftry>
    
    <cfreturn success>
  </cffunction>

  <cffunction name="getPlanDetails" access="public" output="false">
    <cfargument name="planId" type="string" required="true">
    
    <cfset planDetails = {}>
    <cftry>
      
      <!--- Retrieve the plan details by ID --->
      <cfset plan = gateway.plan().find(arguments.planId)>
      
      <cfset planDetails.planId = plan.getId()>
      <cfset planDetails.name = plan.getName()>
      <!--- Add more details as needed --->
      
      <cfcatch>
        <cfset planDetails = {}>
      </cfcatch>
    </cftry>
    
    <cfreturn planDetails>
  </cffunction>

  <cffunction name="deletePlan" access="public" output="false">
    <cfargument name="planId" type="string" required="true">
    
    <cfset success = false>
    <cftry>
      
      <!--- Delete the plan --->
      <cfset result = gateway.plan().delete(arguments.planId)>
      
      <cfif result.isSuccess()>
        <cfset success = true>
      </cfif>
      
      <cfcatch>
        <cfset success = false>
      </cfcatch>
    </cftry>
    
    <cfreturn success>
  </cffunction>
  
  <cffunction name="createCustomer" access="public" output="false">
    <cfargument name="customerData" type="struct" required="true">
    
    <cfset customerId = ''>
    <cftry>
      <cfset request = CreateObject("java", "com.braintreegateway.CustomerRequest")>
      
      <!--- Set customer details based on input arguments --->
      <cfloop collection="#arguments.customerData#" item="key">
        <cfset request[key] = arguments.customerData[key]>
      </cfloop>
      
      <!--- Create the customer --->
      <cfset result = gateway.customer().create(request)>
      
      <cfif result.isSuccess()>
        <cfset customerId = result.getTarget().getId()>
      </cfif>
      
      <cfcatch>
        <cfset customerId = ''>
      </cfcatch>
    </cftry>
    
    <cfreturn customerId>
  </cffunction>
  
  <cffunction name="updateCustomer" access="public" output="false">
    <cfargument name="customerId" type="string" required="true">
    <cfargument name="customerData" type="struct" required="true">
    
    <cfset success = false>
    <cftry>
      
      <!--- Retrieve the customer by ID --->
      <cfset customer = gateway.customer().find(arguments.customerId)>
      
      <!--- Update customer details based on input arguments --->
      <cfloop collection="#arguments.customerData#" item="key">
        <cfset customer[key] = arguments.customerData[key]>
      </cfloop>
      
      <!--- Update the customer --->
      <cfset result = gateway.customer().update(customer)>
      
      <cfif result.isSuccess()>
        <cfset success = true>
      </cfif>
      
      <cfcatch>
        <cfset success = false>
      </cfcatch>
    </cftry>
    
    <cfreturn success>
  </cffunction>

  <cffunction name="getCustomerDetails" access="public" output="false">
    <cfargument name="customerId" type="string" required="true">
    
    <cfset customerDetails = {}>
    <cftry>
      
      <!--- Retrieve the customer details by ID --->
      <cfset customer = gateway.customer().find(arguments.customerId)>
      
      <cfset customerDetails.customerId = customer.getId()>
      <cfset customerDetails.firstName = customer.getFirstName()>
      <cfset customerDetails.lastName = customer.getLastName()>
      <!--- Add more details as needed --->
      
      <cfcatch>
        <cfset customerDetails = {}>
      </cfcatch>
    </cftry>
    
    <cfreturn customerDetails>
  </cffunction>

  <cffunction name="deleteCustomer" access="public" output="false">
    <cfargument name="customerId" type="string" required="true">
    
    <cfset success = false>
    <cftry>
      
      <!--- Delete the customer --->
      <cfset result = gateway.customer().delete(arguments.customerId)>
      
      <cfif result.isSuccess()>
        <cfset success = true>
      </cfif>
      
      <cfcatch>
        <cfset success = false>
      </cfcatch>
    </cftry>
    
    <cfreturn success>
  </cffunction>
  
  
</cfcomponent>
