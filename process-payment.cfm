<cfset Braintree = CreateObject("component", "Braintree")>

<cfset paymentNonce = Trim(Form.paymentNonce)>
<cfset amount = Trim(Form.amount)>

<cfset paymentResult = Braintree.processPayment(paymentNonce, amount)>

<cfcontent type="application/json">
<cfoutput>#SerializeJSON(paymentResult)#</cfoutput>
