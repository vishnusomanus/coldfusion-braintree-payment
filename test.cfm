<cfset Braintree = CreateObject("component", "Braintree")>
<cfset clientToken = Braintree.generateClientToken()>

<!doctype html>
<html lang="en">
<head>

<link rel="stylesheet" type="text/css" href="css/dropin.css" id="braintree-dropin-stylesheet">
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<meta charset="utf-8">
<meta http-equiv="x-ua-compatible" content="IE=Edge"/>
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Drop-in demo</title>
<style>

  html {
    font-family: sans-serif;
    font-size: 16pt;
    background: #f9f9f9;
  }

  body {
    width: 95%;
    max-width: 500px;
    margin: 0 auto;
  }

  .hidden {
    display: none;
  }

  #dropin-container, #checkout-form {
    margin-bottom: 1em;
  }

  #error {
    background: #fee;
    color: tomato;
    padding: 15px;
  }

  #error:empty {
    display: none;
  }

  #ready {
    position: fixed;
    left: -200%;
  }

  input[type="submit"], button {
    font: inherit;
    padding: 0.5em 1em;
    border: 1px solid #d9d9d9;
    background: #f2f2f2;
    background-image: linear-gradient(-180deg,#f2f2f2 0,#e6e6e6 100%);
  }

  button[disabled] {
    display: none;
  }

  footer {
    text-align: center;
  }

  footer a {
    font-size: 16px;
  }
</style>

</head>
<body>
<h1>Braintree Drop-in demo</h1>


<pre id="error"></pre>

<form id="checkout-form">
  <div id="dropin-container"></div>

  <input id="pay-button" type="submit" value="Pay" disabled>
  <button id="create-button" disabled type="button">Create</button>
  <button class="hidden" id="clear-button" type="button">Clear Payment Method</button>
</form>

<div id="update-paypal-configuration" class="hidden">
  <hr>

  <p>Update PayPal Configuration<p/>

  <div>
    <input type="radio" name="flow" onclick="setFlow('vault')" id="paypal-config-vault" checked><label for="paypal-config-vault"> Use Vault flow</label><br>
    <input type="radio" name="flow" onclick="setFlow('checkout')" id="paypal-config-checkout"><label for="paypal-config-checkout"> Use Checkout flow</label>
  </div>
</div>

<pre id="results"></pre>



<script>
if (typeof Object.assign != 'function') {
  Object.assign = function(target, varArgs) { // .length of function is 2
    'use strict';
    if (target == null) { // TypeError if undefined or null
      throw new TypeError('Cannot convert undefined or null to object');
    }

    var to = Object(target);

    for (var index = 1; index < arguments.length; index++) {
      var nextSource = arguments[index];

      if (nextSource != null) { // Skip over if undefined or null
        for (var nextKey in nextSource) {
          // Avoid bugs when hasOwnProperty is shadowed
          if (Object.prototype.hasOwnProperty.call(nextSource, nextKey)) {
            to[nextKey] = nextSource[nextKey];
          }
        }
      }
    }
    return to;
  };
}


</script>
<script src="https://js.braintreegateway.com/web/dropin/1.38.0/js/dropin.min.js"></script>
<script>
    var clientToken = '<cfoutput>#clientToken#</cfoutput>';
  // IE9 doesn't have console defined unless the dev tools are open
  window.console = window.console || {};
  window.console.log = window.console.log || function () {};
</script>
<script>
  var defaultCreateObject = {
    // If you are copying this demo app for your integration,
    // use your own client token or tokenization key
    // authorization: clientToken,
    authorization: 'sandbox_8hfkfvnz_rgtzhzyyvgsk4bhg',
    container: '#dropin-container',
    paypal: {
      flow: 'checkout',
      amount: '10.00', 
      currency: 'USD',
      intent: 'authorize',
      landingPageType: 'login' // hard code this so we get a consistent experience for e2e tests
    },
    venmo: {
      allowDesktop: true
    },
    // preselectVaultedPaymentMethod: true,
    vaultManager: true,
  };
  var dropinInstance;
  var requestPaymentMethodOptions = {};
  var form = document.querySelector('#checkout-form');
  var results = document.querySelector('#results');
  var error = document.querySelector('#error');
  var payButton = document.querySelector('#pay-button');
  var createButton = document.querySelector('#create-button');
  var clearButton = document.querySelector('#clear-button');
  var ready = document.createElement("div");

  ready.id = "ready";

  function getDropinConfig () {
    var query = window.location.search.substring(1);
    var paramPairs, config;

    if (!query) {
      return defaultCreateObject;
    }

    paramPairs = query.split('&');

    config = paramPairs.reduce(function (obj, queryParam) {
      var jsonParsedValue;
      var pair = queryParam.split('=');
      var prop = decodeURIComponent(pair[0]);
      var value = decodeURIComponent(pair[1]);

      // this allows us to pass arrays, booleans, and objects in
      // the query string. If the parsing fails, we fall back to
      // a string value.
      try {
        jsonParsedValue = JSON.parse(value);
        value = jsonParsedValue;

      } catch (e) {}

      obj[prop] = value;

      return obj;
    }, {});

    if (config.mergeWithDefault !== false) {
      config = Object.assign({}, defaultCreateObject, config);
    }

    if (config.dataCollector === true) {
      config.dataCollector = {
        paypal: true
      }
    }

    if (config.threeDSecure === true) {
      config.threeDSecure = {
        amount: '10.00'
      }
      requestPaymentMethodOptions.threeDSecure = {
        email: 'foo@example.com',
        mobilePhoneNumber: '5551231234',
        billingAddress: {
          givenName: 'FirstName',
          surname: 'LastName',
          phoneNumber: '5551231234',
          streetAddress: '123 Street',
          locality: 'Oakland',
          region: 'CA',
          postalCode: '12345',
          countryCodeAlpha2: 'US'
        }
      };
    }

    return config;
  }

  function createDropin () {
    var config = getDropinConfig();

    if (config.showUpdatePayPalMenu) {
      document.querySelector('#update-paypal-configuration').className = '';
    }

    results.textContent = '';
    error.textContent = '';

    braintree.dropin.create(config, function (err, instance) {
      document.body.appendChild(ready);

      if (err) {
        ready.textContent = 'error';
        error.textContent = err.message;
        throw err;
      }

      if (!config.disablePaymentMethodRequestableListeners) {
        if (instance.isPaymentMethodRequestable()) {
          clearButton.className = '';
          payButton.removeAttribute('disabled');
        }

        instance.on('changeActiveView', function (event) {
          console.log('change active view', event);
        });
        instance.on('paymentMethodRequestable', function (event) {
          if (event.paymentMethodIsSelected) {
            clearButton.className = '';
          }
          payButton.removeAttribute('disabled');
          console.log('paymentMethodRequestable', event);
        });

        instance.on('noPaymentMethodRequestable', function (event) {
          clearButton.className = 'hidden';
          payButton.setAttribute('disabled', true);
          console.log('noPaymentMethodRequestable');
        });
      } else {
        payButton.removeAttribute('disabled');
      }

      if (!config.disablePaymentOptionSelectedListener) {
        instance.on('paymentOptionSelected', function (event) {
          console.log('paymentOptionSelected', event.paymentOption);
        });
      }
      createButton.setAttribute('disabled', true);

      dropinInstance = instance;

      ready.textContent = 'ready';
    });
  }

  function setFlow(flow) {
    dropinInstance.updateConfiguration('paypal', 'flow', flow);
    dropinInstance.updateConfiguration('paypalCredit', 'flow', flow);

    if (flow === 'checkout') {
      dropinInstance.updateConfiguration('paypal', 'amount', '9.99');
      dropinInstance.updateConfiguration('paypal', 'currency', 'USD');
      dropinInstance.updateConfiguration('paypalCredit', 'amount', '9.99');
      dropinInstance.updateConfiguration('paypalCredit', 'currency', 'USD');
    } else {
      dropinInstance.updateConfiguration('paypal', 'amount', null);
      dropinInstance.updateConfiguration('paypal', 'currency', null);
      dropinInstance.updateConfiguration('paypalCredit', 'amount', null);
      dropinInstance.updateConfiguration('paypalCredit', 'currency', null);
    }
  }

  createButton.addEventListener('click', createDropin);
  form.addEventListener('submit', function (event) {
    event.preventDefault();

    dropinInstance.requestPaymentMethod(requestPaymentMethodOptions, function (err, payload) {
      if (err) {
        clearButton.className = 'hidden';
        error.textContent = err.message;
        results.textContent = '';
      } else {
        clearButton.className = '';
        results.textContent = JSON.stringify(payload, null, 2);
        error.textContent = '';
        console.log(payload)
        $.ajax({
                url: 'process-payment.cfm',
                type: 'POST',
                data: {
                  paymentNonce: payload.nonce,
                  amount: 15,
                  clientToken: clientToken
                },
                success: function(response) {
                  // Handle the server response
                  if (response.success) {
                    // Payment successful, show success message to the user
                    console.log('Payment successful');
                    alert('Payment successful');
                  } else {
                    // Payment failed, show error message to the user
                    console.error('Payment failed');
                  }
                }
              });
      }
    });
  }, false);

  clearButton.addEventListener('click', function () {
    dropinInstance.clearSelectedPaymentMethod();
    clearButton.className = 'hidden';
  });



  createDropin();
</script>
<!--- <cfset getCustomerDetails = Braintree.getCustomerDetails("18181138396")> 
<cfdump var="#getCustomerDetails#">--->


<!--- <cfset customerDetails = Braintree.createCustomer('Mike','Jones','mike.')> --->
<!--- <cfdump var="#customerDetails#"> --->


</body>
</html>
