<!--- Get transaction ID and amount from URL --->
<cfset transactionId = url.transactionId>

<!--- Call capturePayment function --->
<cfset Braintree = CreateObject("component", "Braintree")>
<cfset result = Braintree.voidPayment(transactionId)>

<!--- Dump the return value --->
<cfdump var="#result#">
