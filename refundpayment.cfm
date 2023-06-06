<!--- Get transaction ID and amount from URL --->
<cfset transactionId = url.transactionId>
<cfset amount = url.amount>

<!--- Call capturePayment function --->
<cfset Braintree = CreateObject("component", "Braintree")>
<cfset result = Braintree.createRefund(transactionId, amount)>

<!--- Dump the return value --->
<cfdump var="#result#">
