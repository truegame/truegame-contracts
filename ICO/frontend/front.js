"use strict";

var gasPrice, gasAmount, web3, Web3, adminAddress;



function init() {

    setTimeout(function () {

        if (typeof window.web3 === 'undefined') {
            showTimeNotification("top", "right", "Please enable metamask.")
        } else if (window.web3.eth.defaultAccount == undefined) {
            showTimeNotification("top", "right", "Please unlock metamask.")

        } else if (web3.currentProvider.isMetaMask === true) {
            if (web3.eth.defaultAccount == undefined) {
                web3.eth.defaultAccount = window.web3.eth.defaultAccount
                adminAddress = web3.eth.defaultAccount;
            }

            // web3.eth.getAccounts( accounts => console.log(accounts[0])) 
        } else {

            // Checks Web3 support
            if (typeof web3 !== 'undefined' && typeof Web3 !== 'undefined') {
                // If there's a web3 library loaded, then make your own web3
                web3 = new Web3(web3.currentProvider);
            } else if (typeof Web3 !== 'undefined') {
                // If there isn't then set a provider
                //var Method = require('./web3/methods/personal');
                web3 = new Web3(new Web3.providers.HttpProvider(connectionString));

                if (!web3.isConnected()) {

                    $("#alert-danger-span").text(" Problem with connection to the newtwork. Please contact " + supportEmail + " abut it. ");
                    $("#alert-danger").show();
                    return;
                }
            } else if (typeof web3 == 'undefined' && typeof Web3 == 'undefined') {

                Web3 = require('web3');
                web3 = new Web3();
                web3.setProvider(new web3.providers.HttpProvider(onnectionString));
            }

        }

        gasPrice = 20000000000;
        gasAmount = 4000000;


        if (checkMetamaskStatus()) {
          //  whiteListUserMultiple();
        }
    }, 1000);
}




function isUserWhitelisted() {

    return new Promise(function (resolve, reject) {

        var toAddress = $("#white-list-address").val();

        if (checkMetamaskStatus()) {

            var whiteListContract = web3.eth.contract(whiteListABI);
            var whiteListHandle = whiteListContract.at(whiteListContractAddress);
            progressActionsBefore();

            whiteListHandle.whiteList(toAddress, {
                from: adminAddress,
                gasPrice: gasPrice,
                gas: gasAmount
            }, function (error, result) {

                if (!error) {

                    if (result) {
                        var message = "Address " + toAddress + " has been white listed. "
                        progressActionsAfter(message, true);
                        resolve(false);
                    } else {

                        var message = "Address " + toAddress + " hasn't been white listed. "
                        progressActionsAfter(message, true);
                        resolve(true);
                    }

                } else {
                    // displayExecutionError(error);
                    console.error(error);
                }
            });
        }
    })

}

function whiteListUserMultiple() {

    var whitelisted;

    // this here is an example of passing an array of addressess to the function. 
    var users = ["0x73810Bfb450352848F73177b6BB80322456380fE", "0xe3C3A472cd403B558bc83a46C032E95Ab0c5c639"]

    //var toAddress = $("#white-list-address").val();
    if (checkMetamaskStatus()) {

        var whiteListContract = web3.eth.contract(whiteListABI);
        var whiteListHandle = whiteListContract.at(whiteListContractAddress);
        setTimeout(function () {

            whiteListHandle.addToWhiteListMultiple(users, {
                from: adminAddress,
                gasPrice: gasPrice,
                gas: gasAmount
            }, function (error, result) {

                if (!error) {
                    progressActionsBefore();
                    console.log(result)
                    var log = whiteListHandle.LogWhiteListedMultiple({
                        whiteListedNum: whitelisted
                    });

                    log.watch(function (error, res) {
                        if (!error && res.transactionHash == result) {
                            var message = "Batch of users has been whitelisted.";
                            $("#total-whitelisted").val(res.args.whitelisted)
                            progressActionsAfter(message, true);
                        }
                    });
                } else {
                    // displayExecutionError(error);
                    console.error(error);
                }
            });
        }, 100);
    }
}

function whiteListUser() {

    isUserWhitelisted().then(function (res, error) {

        if (res) {
            var user, whitelisted;
            var toAddress = $("#white-list-address").val();
            if (checkMetamaskStatus()) {

                var ICOContradct = web3.eth.contract(whiteListABI);
                var whiteListHandle = ICOContradct.at(whiteListContractAddress);
                setTimeout(function () {

                    whiteListHandle.addToWhiteList(toAddress, {
                        from: adminAddress,
                        gasPrice: gasPrice,
                        gas: gasAmount
                    }, function (error, result) {

                        if (!error) {
                            progressActionsBefore();
                            console.log(result)
                            var log = whiteListHandle.LogWhiteListed({
                                user: toAddress,
                                whiteListedNum: whitelisted,
                                transactionHash: result
                            });

                            log.watch(function (error, res) {

                                if (!error && res.transactionHash == result) {
                                    var message = "User " + res.args.user + " has been whitelisted.";
                                    $("#total-whitelisted").val(res.args.totalWhiteListed)
                                    progressActionsAfter(message, true);
                                    log.stopWatching();
                                }
                            });
                        } else {
                            // displayExecutionError(error);
                            console.error(error);
                        }
                    });
                }, 100);
            }
        }
    })
}
//  }, 10);



function progressActionsAfter(message, success) {

    if (success) {
        $("#message-status-title").html('Contract executed...<i class = "fa fa-check-circle-o" aria-hidden = "true" style="font-size:28px;color:green">');
    } else {
        $("#message-status-title").html("Contract executed...<img src='no.png' height='40' width='43'>");
    }

    $("#message-status-body").html("<BR>" + message);

}





function progressActionsBefore() {


    $("#message-status-title").html("");
    $("#message-status-body").html("");
    $("#progress").modal();
    $("#message-status-title").html('Verifying contract... <i class="fa fa-refresh fa-spin" style="font-size:28px;color:red"></i>');
    setTimeout(function () {
        $("#message-status-title").html('Executing contract call..<i class="fa fa-spinner fa-spin" style="font-size:28px;color:green"></i>');
    }, 10);

}

function showTimeNotification(from, align, text) {

    var type = ['', 'info', 'success', 'warning', 'danger', 'rose', 'primary'];

    var color = Math.floor((Math.random() * 6) + 1);

    $.notify({
        icon: "notifications",
        message: text,
        allow_dismiss: true

    }, {
        type: type[color],
        timer: 300,
        placement: {
            from: from,
            align: align
        }
    });
}

function checkMetamaskStatus() {

    if (typeof window.web3 === 'undefined') {
        showTimeNotification("top", "right", "Please enable metamask.")
        return false;
    } else if (window.web3.eth.defaultAccount == undefined) {
        showTimeNotification("top", "right", "Please unlock metamask.")
        return false;

    }
    web3.eth.defaultAccount = window.web3.eth.defaultAccount;
    return true;
}

function convertTimestamp(timestamp, onlyDate) {
    var d = new Date(timestamp * 1000), // Convert the passed timestamp to milliseconds
        yyyy = d.getFullYear(),
        mm = ('0' + (d.getMonth() + 1)).slice(-2), // Months are zero based. Add leading 0.
        dd = ('0' + d.getDate()).slice(-2), // Add leading 0.
        hh = d.getHours(),
        h = hh,
        min = ('0' + d.getMinutes()).slice(-2), // Add leading 0.
        sec = d.getSeconds(),
        ampm = 'AM',
        time;


    yyyy = ('' + yyyy).slice(-2);

    if (hh > 12) {
        h = hh - 12;
        ampm = 'PM';
    } else if (hh === 12) {
        h = 12;
        ampm = 'PM';
    } else if (hh == 0) {
        h = 12;
    }

    if (onlyDate) {
        time = mm + '/' + dd + '/' + yyyy;

    } else {
        // ie: 2013-02-18, 8:35 AM	
        time = yyyy + '-' + mm + '-' + dd + ', ' + h + ':' + min + ' ' + ampm;
        time = mm + '/' + dd + '/' + yyyy + '  ' + h + ':' + min + ':' + sec + ' ' + ampm;
    }
    return time;
}


function formatNumber(number) {
    number = number.toFixed(0) + '';
    var x = number.split('.');
    var x1 = x[0];
    var x2 = x.length > 1 ? '.' + x[1] : '';
    var rgx = /(\d+)(\d{3})/;
    while (rgx.test(x1)) {
        x1 = x1.replace(rgx, '$1' + ',' + '$2');
    }
    return x1 + x2;
}

$(document).ready(function () {


    $("#whitelist").click(function () {
        whiteListUser();
    });

    $("#is-whitelisted").click(function () {
        isUserWhitelisted();
    });
})