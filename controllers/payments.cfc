component accessors="true" {

    property PaymentService;
    property InvoiceService;
    property BookingService;
    property TransactionService;
    property PostCCTransactionService;
    property EmailService;
    property CachedDataService;
    property ErrorNTestHandler;
    variables.emailsNotifications = application.emailsNotifications;

    public any function init(fw) {
        variables.fw = fw;
        return this;
    }

    function error(rc) {
        rc.title = 'An error occurred';
        rc.message = 'Something went wrong while processing your request.';
    }

    function autoCharge(rc){
        error_test_handler = getErrorNTestHandler();

        if(isDefined("form.txtBookingNumber")){

            if( error_test_handler.isDoingTestNow() ){
                writeLog(
                    type = 'information',
                    file = 'OnlinePaymentLogByTest',
                     text="booking='#form.txtBookingNumber#'  
				        CC_id='#form.rdo_CCs#' Info='Posted from confirmation to autoCharge'"
                );
            }
            
            sErrorMessage2 = getPaymentService().enrollAutoCharge(
                rdo_ccs = form.rdo_CCs,
                txtBookingNumber = form.txtBookingNumber
            );
            if(len(sErrorMessage2) gt 0){
                if(error_test_handler.isDoingTestNow()){
                    writeLog(
                        type = 'information',
                        file = 'OnlinePaymentLogByTest',
                        text = 'booking=''#form.txtBookingNumber#''  CC_id=''#form.rdo_CCs#'' Info=''Error happened at oracle side:#sErrorMessage2#'''
                    );
                }
                writeLog(
                    type = 'error',
                    file = 'OnlinePaymentErr',
                    text = 'Error=''Error happened when calling enroll_autocharge to enroll:#sErrorMessage2#''  booking=''#Client.currentBookingNumber#'' CC_id=''#arrExistingCC[1].CREDIT_CARD_ID#'''
                );
                client.ccSelectedMessage = 'Sorry, a technical error happened when enrolling this Credit Card to Automatical-Charge. Administrtor was notified and will solve the problem as soon as possible.';
            }else{
                client.ccSelectedMessage = 'Thank you for enrolling this Credit Card to Automatical-Charge.';
            }
            structDelete(client, 'currentbookingnumber');
            structDelete(client, 'currentccnumber');
            structDelete(client, 'failedbookfinddt');
            structDelete(client, 'failedbookfindtries');
            structDelete(client, 'failedpaymentdt');
            structDelete(client, 'failedpaymenttries');
            structDelete(client, 'paymentsuccessmessage');
            structDelete(client, 'remainingbalance');
            variables.fw.redirect(action = 'payemtns.autoCharge');
        }else if(isDefined('Client.ccSelectedMessage')){
            writeLog(
                type = 'information',
                file = 'OnlinePaymentLogByTest',
                text = 'Info=''SelectCCAutoCharge.cfm: after CC selection'''
            );
        } else {
            variables.fw.redirect(action = 'main.default');
        }
    }

    function confirmation(rc) {
        rc.SandalsBookingNumber = rc.SandalsBookingNumber ?: 0;
        rc.MinPayment = rc.MinPayment ?: 0;
        rc.PaymentAmount = rc.PaymentAmount ?: '';
        rc.PaymentReason = rc.PaymentReason ?: '';
        rc.MessageID = rc.MessageID ?: '';
        rc.Gross = rc.Gross ?: '';
        rc.paid = rc.paid ?: '';
        rc.balance = rc.balance ?: '';
        rc.DepositDueAmt = rc.DepositDueAmt ?: 0;
        rc.DepositDueDt = rc.DepositDueDt ?: '';
        rc.Email = rc.Email ?: '';
        rc.BookingNumber = rc.BookingNumber ?: '';
        rc.GroupName = rc.GroupName ?: '';
        rc.LastName = rc.LastName ?: '';
        rc.CheckInDt = rc.CheckInDt ?: '';
        rc.ResortCode = rc.ResortCode ?: '';
        rc.Nights = rc.Nights ?: 0;
        rc.RoomCategory = rc.RoomCategory ?: '';
        rc.Adults = rc.Adults ?: 0;
        rc.children = rc.children ?: 0;
        rc.Infants = rc.Infants ?: 0;
        rc.PaymentType = rc.PaymentType ?: '';
        rc.comment = rc.comment ?: '';

        error_test_handler = getErrorNTestHandler();

        rc.isPaymentSuccessMessageNotDefined = not isDefined('Client.PaymentSuccessMessage');
        if (rc.isPaymentSuccessMessageNotDefined) {
            client.PaymentSuccessMessage = '';
        }

        rc.isPaymentSucessMessageNotEmpty = trim(Client.PaymentSuccessMessage) IS NOT '';
        try {
            rc.structCardInfo = {}

            rc.isMonthNotDefined = !isDefined('session.OPPaymentInfo.month');
            if (rc.isMonthNotDefined) {
                variables.fw.redirect(action = 'main.default', queryString = 'msg=503');
            }

            rc.NewInvoiceID = getInvoiceService().getNewInvoiceId();
            rc.DAYPART = dateFormat(now(), 'DDMMYY')
            rc.INVOICE = rc.DAYPART & rc.NewInvoiceID

            writeLog(
                type = 'information',
                file = 'OnlinePaymentLog',
                text = 'booking=''#rc.SandalsBookingNumber#''  Info=''Called obe_pack.get_invoice_id, NewInvoiceID:#rc.NewInvoiceID#--INVOICE:#rc.INVOICE#'' CardNumber=''#session.OPPaymentInfo.CreditCard#'' amount=''#rc.PaymentAmount#'''
            );

        } catch (any ex) {
            error_test_handler.reportError(
                ex,
                error_test_handler.GETTING_INVOICE,
                'getting new invoice number, booking number:#rc.sandalsBookingNumber#'
            )
        }

        rc.qryAssignment = getBookingService().getBookingDetails(rc.SandalsBookingNumber);
        rc.isBookingNumberNotDefined = not isDefined('rc.SandalsBookingNumber');

        rc.isBookingDetailsEmpty = (rc.qryAssignment.book_no IS '0') OR (rc.qryAssignment.resv_no IS '0');

        try {
            if (rc.isBookingDetailsEmpty) {
                throw(
                    message = 'No RSV side record was found for the booking ''#form.sandalsbookingnumber#''. Process is stopped in order to prevent credit card charging.'
                );
                return;
            }

            writeLog(
                type = 'information',
                file = 'OnlinePaymentLogByTest',
                text = 'booking=''#rc.SandalsBookingNumber#''  Info=''No reservation info found'' CardNumber=''#session.OPPaymentInfo.CreditCard#'' amount=''#rc.PaymentAmount#'''
            );
        } catch (any ex) {
            error_test_handler.reportError(
                ex,
                error_test_handler.GETTING_INVOICE,
                'getting booking #rc.sandalsbookingnumber# details'
            )
        }


        qry_cctypes = getCachedDataService().getCCTypes();
        cc_type_code = getPaymentService().getCCCodeById(session.OPPaymentInfo.CardType, qry_cctypes);

        isCCStateNull = session.OPPaymentInfo.CCState is '';
        dState = isCCStateNull ? session.OPPaymentInfo.otherState : session.OPPaymentInfo.CCState;

        exp_date = '#session.OPPaymentInfo.month#' & '/01/' & '#session.OPPaymentInfo.year#';
        isTest = application.isDev;

        var transactionParams = {
            p_amount: rc.PaymentAmount,
            p_cardtype: cc_type_code,
            p_CardNumber: session.OPPaymentInfo.CreditCard,
            p_Cvv2Cod: session.OPPaymentInfo.cvv2Code,
            p_ExpirationMonth: dateFormat(exp_date, 'MM'),
            p_ExpirationYear: dateFormat(exp_date, 'YYYY'),
            p_CardholderName: '#session.OPPaymentInfo.CCFirstName# #session.OPPaymentInfo.CCLastName#',
            p_streetaddress: session.OPPaymentInfo.CCAddress,
            p_city: session.OPPaymentInfo.CCCity,
            p_state: dState,
            p_zipcode: session.OPPaymentInfo.CCZipCode,
            p_isOnDev: isTest,
            p_bookingNumber: rc.SandalsBookingNumber,
            p_country: session.OPPaymentInfo.CCCountry,
            p_checkInDate: rc.CheckInDt
        };

        try {
            rc.authorizationData = getTransactionService().processTransaction(transactionParams = transactionParams);

            try {
                rc.isCCSystemv2 = true;
                if (rc.isCCSystemv2) {
                    writeLog(
                        type = 'information',
                        file = 'OnlinePaymentLogByTest',
                        text = 'cc_transaction=''CCSystemV2''  isCCSystemv2=''#rc.isCCSystemv2#'' booking=''#form.sandalsbookingnumber#''  Info=''Real CC, Call WS processTransaction'' CardNumber=''#session.OPPaymentInfo.CreditCard#'' amount=''#form.paymentamount#'''
                    )
                }
            } catch (any ex) {
                error_test_handler.reportError(
                    ex,
                    error_test_handler.CHARGING_CC,
                    'making CC transaction:  #session.OPPaymentInfo.CCFirstName#--#session.OPPaymentInfo.CCLastName#--#form.sandalsBookingNumber#--#form.paymentAmount#'
                )
            }


            rc.PaymentResultsStructObj = rc.authorizationData;
            rc.structCCResponse = rc.PaymentResultsStructObj.result;
            rc.structCardInfo.BookingNumber = '#form.sandalsbookingnumber#'
            rc.structCardInfo.Email = '#form.email#'
            rc.structCardInfo.Amount = form.paymentAmount
            rc.structCardInfo.Message = ''
            rc.structCardInfo.AuthorizationCode = ''
            rc.structCardInfo.Approved = 'False'


            try {
                if (rc.isCCSystemv2) {
                    hasErrorFlag = structKeyExists(rc.PaymentResultsStructObj.result.error, 'code');
                    if (hasErrorFlag) {
                        writeLog(
                            type = 'information',
                            file = 'OnlinePaymentLogByTest',
                            text = 'booking=''#form.sandalsbookingnumber#''  Info=''CCsystemV2, error in rc.PaymentResultsStructObj.result.error--#hasErrorFlag#'' amount=''#form.paymentamount#'''
                        )
                        rc.structCardInfo.Message = 'There was a problem processing your credit card; please try again'
                        rc.structCardInfo.AuthorizationCode = ''
                        rc.structCardInfo.Approved = 'False'

                        writeLog(
                            type = 'information',
                            file = 'PostCC_transaction',
                            text = 'status=''FAILED'' booking=''#form.sandalsbookingnumber#'' Info=''GOP CCsystemV2, error in rc.PaymentResultsStructObj.result.error--#hasErrorFlag#, errorMessage=#rc.PaymentResultsStructObj.result.error#'' amount=''#form.paymentamount#'' REMOTE_ADDR=''#CGI.REMOTE_ADDR#'' USER_AGENT=''#CGI.HTTP_USER_AGENT#'''
                        )
                    }
                }
            } catch (any ex) {
                writeLog(
                    type = 'information',
                    file = 'PostCC_transaction',
                    text = 'status=''FAILED'' booking=''#form.sandalsbookingnumber#'' Info=''GOP CCsystemV2 Transacction Failed'' amount=''#form.paymentamount#'' REMOTE_ADDR=''#CGI.REMOTE_ADDR#'' USER_AGENT=''#CGI.HTTP_USER_AGENT#'''
                );
                error_test_handler.reportError(
                    ex,
                    error_test_handler.READING_CC_CHARGEINFO,
                    'reading CC transaction info:  #session.OPPaymentInfo.CCFirstName#--#session.OPPaymentInfo.CCLastName#--#form.sandalsBookingNumber#--#form.paymentAmount#'
                )
            }

            writeLog(
                type = 'information',
                file = 'OnlinePaymentLogByTest',
                text = 'booking=''#form.sandalsbookingnumber#''  Info=''CCsystemV2, rc.PaymentResultsStructObj.result.error--#hasErrorFlag#,OK''  amount=''#form.paymentamount#'''
            )

            isTransactionApproved = rc.structCCResponse.transaction.approved;
            if (isTransactionApproved) {
                AuthorizationCode = rc.structCCResponse.transaction.authCode ?: '';
                v_new_token_string = '#rc.structCCResponse.transaction.token#'
                v_new_response_code = '#rc.structCCResponse.transaction.responseCode#'
                v_cc_transaction_id = '#rc.structCCResponse.transaction.orderNumber#'
                v_processor = '#rc.structCCResponse.transaction.gateway#';

                writeLog(
                    type = 'information',
                    file = 'OnlinePaymentLogByTest',
                    text = 'booking=''#form.sandalsbookingnumber#''  Info=''CCsystemV2, Approved!--#rc.structCCResponse.success#--#rc.structCCResponse.transaction.authCode#''  amount=''#form.paymentamount#'''
                );

                rc.structCardInfo.Message = 'Credit Card transaction was approved'
                rc.structCardInfo.Approved = 'True'
                writeLog(
                    type = 'information',
                    file = 'PostCC_transaction',
                    text = 'status=''PASSED'' CCRESPONSE=''#v_new_response_code#'' booking=''#form.sandalsbookingnumber#'' Info=''GOP CCsystemV2 Transacction Approved'' amount=''#form.paymentamount#'' transacctionid=''#v_cc_transaction_id#'' processor=''#v_processor#'' REMOTE_ADDR=''#CGI.REMOTE_ADDR#'' USER_AGENT=''#CGI.HTTP_USER_AGENT#'''
                )

                if (rc.structCardInfo.Approved) {
                    rc.ccType = getPaymentService().getCCCode4DBById(session.OPPaymentInfo.CardType, qry_cctypes);
                    writeLog(
                        type = 'information',
                        file = 'OnlinePaymentLogByTest',
                        text = 'booking=''#form.sandalsbookingnumber#''  Info=''Call INSERT_CREDIT_CARD'' CardNumber=''#session.OPPaymentInfo.CreditCard#'' amount=''#form.paymentamount#'''
                    );

                    writeLog(
                        type = 'information',
                        file = 'OnlinePaymentLogByTest',
                        text = 'booking=''#form.sandalsbookingnumber#''  Info=''Call INSERT_CREDIT_CARD....done'' CardNumber=''#session.OPPaymentInfo.CreditCard#'' amount=''#form.paymentamount#'''
                    );
                }

                transactionStruct = {
                    ccType: rc.ccType,
                    ccName: session.OPPaymentInfo.CCFirstName & ' ' & session.OPPaymentInfo.CCLastName,
                    exp_date: exp_date,
                    SandalsBookingNumber: rc.SandalsBookingNumber,
                    PaymentAmount: rc.PaymentAmount,
                    AuthorizationCode: AuthorizationCode,
                    SandalsBookingNumber2: rc.SandalsBookingNumber,
                    newTokenString: v_new_token_string,
                    processor: uCase(v_processor),
                    ccTransactionId: v_cc_transaction_id,
                    ccAddress: session.OPPaymentInfo.CCAddress,
                    blankField: '',
                    ccCity: session.OPPaymentInfo.CCCity,
                    ccState: session.OPPaymentInfo.CCState,
                    ccCountry: session.OPPaymentInfo.CCCountry,
                    ccZipCode: session.OPPaymentInfo.CCZipCode,
                    Email: rc.Email
                };

                commentStruct = {
                    SandalsBookingNumber: rc.SandalsBookingNumber,
                    commentText: 'Type:#rc.PaymentType# comment:#rc.comment#',
                    source: 'WEBGOLD',
                    emptyString: ''
                };

                transactionSucceed = getPostCCTransactionService().processPostCCTransaction(
                    transactionParams = transactionStruct,
                    commentStruct = commentStruct
                );


                po_sucess_val = transactionSucceed.po_sucess_val
                po_msg = transactionSucceed.po_msg;
                isTransactionSucceed = transactionSucceed.success;

                emailsNotifications = variables.emailsNotifications ?: '';

                inetOBJ = createObject('java', 'java.net.InetAddress');
                inetOBJ = inetOBJ.getLocalHost();
                host = inetOBJ.getHostName();
                if (isTransactionSucceed) {
                    Client.currentBookingNumber = form.sandalsbookingnumber
                    Client.currentCCNumber = session.OPPaymentInfo.CreditCard
                    Client.remainingBalance = form.balance - form.PaymentAmount

                    writeLog(
                        type = 'information',
                        file = 'OnlinePaymentLogByTest',
                        text = 'booking=''#form.sandalsbookingnumber#'' Info=''Before going to the last page, remainig balance is:#Client.remainingBalance#''  paying_amount=''#form.paymentamount#'' balance=''#form.balance#'''
                    );
                    writeLog(
                        type = 'information',
                        file = 'PostCC_transaction',
                        text = 'insert_reservation_comment: booking=''#rc.SandalsBookingNumber# Type:#rc.PaymentType# comment:#rc.comment# po_sucess_val:#po_sucess_val# po_msg:#po_msg#'''
                    );

                    EmailService.sendEmail(form, emailsNotifications, host);
                }
            } else {
                writeLog(
                    type = 'information',
                    file = 'OnlinePaymentLogByTest',
                    text = 'booking=''#form.sandalsbookingnumber#''  Info=''CCsystemV2, Failed!--#rc.structCCResponse.success#--#structCardInfo.AuthorizationCode#'' CardNumber=''#session.OPPaymentInfo.CreditCard#'' amount=''#form.paymentamount#'''
                );

                rc.structCardInfo.Message = 'Your Credit Card has been declined'
                rc.structCardInfo.AuthorizationCode = ''
                rc.structCardInfo.Approved = 'False'

                writeLog(
                    type = 'information',
                    file = 'PostCC_transaction',
                    text = 'status=''FAILED'' CCRESPONSE=''#v_new_response_code#'' booking=''#form.sandalsbookingnumber#'' Info=''GOP CCsystemV2 Transacction Was Not Approved'' amount=''#form.paymentamount#'' transacctionid=''#v_cc_transaction_id#'' processor=''#v_processor#'' REMOTE_ADDR=''#CGI.REMOTE_ADDR#'' USER_AGENT=''#CGI.HTTP_USER_AGENT#'''
                );
            }
        } catch (any e) {
            rc.errorMessage = 'An error occurred while processing the transaction: ' & e.message;
            EmailService.sendTransactionErrorEmail(form, host, e);
            AuthorizationCode = rc.structCCResponse.transaction.authCode ?: '';
            v_new_token_string = '#rc.structCCResponse.transaction.token#'
            v_new_response_code = '#rc.structCCResponse.transaction.responseCode#'
            v_cc_transaction_id = '#rc.structCCResponse.transaction.orderNumber#'
            v_processor = '#rc.structCCResponse.transaction.gateway#';
            writeLog(
                type = 'information',
                file = 'OnlinePaymentErr',
                text = 'status=''FAILED'' CCRESPONSE=''#v_new_response_code#'' booking=''#form.sandalsbookingnumber#'' Info=''GOP inserting CC transaction info to DB'' amount=''#form.paymentamount#'' transacctionid=''#v_cc_transaction_id#'' processor=''#v_processor#'' REMOTE_ADDR=''#CGI.REMOTE_ADDR#'' USER_AGENT=''#CGI.HTTP_USER_AGENT#'', ExcMessage: #cfcatch.message#, ExcDetail: #cfcatch.detail# '
            );

            error_test_handler.reportError(
                cfcatch,
                error_test_handler.INSERTING_DB_RECORDS,
                'inserting CC transaction info to DB:  #rc.structCardInfo.AuthorizationCode#--#form.sandalsBookingNumber#--#form.paymentAmount#'
            );


            error_test_handler.reportError(
                e,
                error_test_handler.SENDING_EMAIL,
                'sending out email:  #form.sandalsBookingNumber#--#form.paymentAmount#'
            );
        }
    }

    function processPayment(rc) {
        rc.SandalsBookingNumber = rc.SandalsBookingNumber ?: '';
        rc.MinPayment = rc.MinPayment ?: '';
        rc.PaymentAmount = rc.PaymentAmount ?: '';
        rc.PaymentReason = rc.PaymentReason ?: '';
        rc.MessageID = rc.MessageID ?: '';
        rc.Gross = rc.Gross ?: '';
        rc.paid = rc.paid ?: '';
        rc.balance = rc.balance ?: '';
        rc.DepositDueAmt = rc.DepositDueAmt ?: '';
        rc.DepositDueDt = rc.DepositDueDt ?: '';
        rc.Email = rc.Email ?: '';
        rc.BookingNumber = rc.BookingNumber ?: '';
        rc.GroupName = rc.GroupName ?: '';
        rc.LastName = rc.LastName ?: '';
        rc.CheckInDt = rc.CheckInDt ?: '';
        rc.ResortCode = rc.ResortCode ?: '';
        rc.Nights = rc.Nights ?: '';
        rc.RoomCategory = rc.RoomCategory ?: '';
        rc.Adults = rc.Adults ?: '';
        rc.children = rc.children ?: '';
        rc.Infants = rc.Infants ?: '';
        rc.PaymentType = rc.PaymentType ?: '';
        rc.comment = rc.comment ?: '';
        rc.EditPayment = rc.EditPayment ?: '';
        rc.ConfirmPayment = rc.ConfirmPayment ?: '';

        rc.Resorts = getCachedDataService().getAllResorts();
        error_test_handler = new model.utils.ErrorNTestHandler().initurl(url);

        rc.qry_cctypes = getCachedDataService().getCCTypes();

        ThisYear = year(now());
        ThisMonth = month(now());

        rc.structBookingInfo = {};
        var ErrorMessage = '';
        hasFormBooking = structKeyExists(form, 'BookingNumber');
        paymentService = getPaymentService();

        session.OPPaymentInfo = {};

        if (hasFormBooking) {
            hasWTheBookingNumber = left(form.BookingNumber, 1) == 'W';
            if (hasWTheBookingNumber) {
                confirmation_no = form.BookingNumber;
                qry = getBookingService().validateReservation(confirmation_no = confirmation_no);

                queryHasElements = qry.recordCount > 0;
                if (queryHasElements) {
                    form.BookingNumber = qry.BOOK_NO;
                    return;
                }
                ErrorMessage = 'Confirmation number is not valid';
            }

            isNotEmailRemainder = compareNoCase(PaymentReason, 'EmailReminder') == 0;
            if (isNotEmailRemainder) {
                rc.structBookingInfo = paymentService.verifyBooking(
                    Email = form.Email,
                    BookingNumber = form.BookingNumber
                );
                return;
            }

            rc.structBookingInfo = paymentService.checkGroupBooking(
                BookingNumber = form.BookingNumber,
                GroupName = form.GroupName,
                CheckInDate = form.CheckinDt,
                ResortCode = form.ResortCode
            );
        }

        var isValidCCType = paymentService.validateCreditCardType(
            ccnumber = form.creditcard,
            cctype = form.cardtype,
            cccvv = form.cvv2code
        );

        rc.ContinueDisplay = true;
        var Message = 'Please correct the following error(s) by selecting <strong>Edit</strong>.<br>';

        if (!isValidCCType.success) {
            rc.continueDisplay = false;
            Message = isValidCCType.message;
        }

        var isCreditCardNumeric = isNumeric(CreditCard);
        if (!isCreditCardNumeric) {
            rc.continueDisplay = false;
            Message = Message & 'You did not enter a valid credit card number<br>';
        }

        var isPaymentAmountNumeric = isNumeric(PaymentAmount);
        if (!isPaymentAmountNumeric) {
            rc.continueDisplay = false;
            Message = Message & 'You did not enter a valid payment amount in XX.XX format';
        }

        var isPaymentAmountLessThanMin = PaymentAmount < MinPayment;
        if (isPaymentAmountNumeric && isPaymentAmountLessThanMin) {
            rc.continueDisplay = false;
            Message = Message & 'A minimum payment of #MinPayment# must be paid';
        }

        var isPaymentAmountGreaterThanMax = PaymentAmount > 99999;
        if (isPaymentAmountNumeric && isPaymentAmountGreaterThanMax) {
            rc.continueDisplay = false;
            Message = Message & 'The maximum charge allowed per transaction is $99,999.00';
        }

        tmpCreditCardNumber1 = left(Form.creditcard, 1);

        cardTypeMap = {'2': 1, '3': 3, '6': 4, '5': 1, '4': 2};

        Form.CardType = cardTypeMap[tmpCreditCardNumber1] ?: 0;

        session.OPPaymentInfo = {
            CardType: Form.CardType,
            CreditCard: Form.creditcard,
            CCFirstName: CCFirstName,
            CCLastName: CCLastName,
            CCAddress: CCAddress,
            CCCountry: CCCountry,
            CCCity: CCCity,
            CCState: CCState,
            otherState: otherState,
            CCZipCode: CCZipCode,
            cvv2Code: cvv2Code,
            month: Form.Month,
            year: Form.year
        };

    }

    function default(rc) {
        variables.fw.redirect(action = 'main.default', queryString = 'msg=503');
    }


}
