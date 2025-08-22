component accessors="true" {

    variables.datasourceWebgold = application.isDev ? 'webgold' : 'webgold_production';

    public numeric function getNewInvoiceId() {
        cfstoredproc(procedure = "obe_pack.get_invoice_id", datasource = variables.datasourceWebgold) {
            cfprocparam(type = "out", cfsqltype = "numeric", variable = "NewInvoiceID");
        }
        return NewInvoiceID;
    }


    public string function enrollAutoCharge(required numeric rdo_ccs, required string txtBookingNumber) {
        sErrorMessage2 = '';
        try {
            cfstoredproc(procedure = "enroll_autocharge", datasource = variables.datasourceWebgold) {
                cfprocparam(type = "IN", cfsqltype = "cf_sql_numeric", value = rdo_ccs);
                cfprocparam(type = "IN", cfsqltype = "CF_SQL_VARCHAR", value = txtBookingNumber);
                cfprocparam(type = "out", cfsqltype = "CF_SQL_VARCHAR", variable = "sErrorMessage2");
            }
            return trim(sErrorMessage2);
        } catch (any e) {
            return 'Error happened when calling enroll_autocharge to enroll: ' & e.message;
        }
    }

    public boolean function insertCreditCard(required struct transactionStruct) {
        try {
            cfstoredproc(procedure = "INSERT_CREDIT_CARD_LUCEE", datasource = variables.datasourceWebgold) {
                cfprocparam(type = "IN", cfsqltype = "CF_SQL_VARCHAR", value = transactionStruct.ccType);
                cfprocparam(type = "IN", cfsqltype = "CF_SQL_VARCHAR", value = transactionStruct.ccName);
                cfprocparam(type = "IN", cfsqltype = "CF_SQL_VARCHAR", value = transactionStruct.exp_date);
                cfprocparam(type = "IN", cfsqltype = "CF_SQL_VARCHAR", value = transactionStruct.SandalsBookingNumber);
                cfprocparam(type = "IN", cfsqltype = "CF_SQL_INTEGER", value = transactionStruct.PaymentAmount);
                cfprocparam(type = "IN", cfsqltype = "CF_SQL_VARCHAR", value = transactionStruct.AuthorizationCode);
                cfprocparam(type = "IN", cfsqltype = "CF_SQL_VARCHAR", value = transactionStruct.SandalsBookingNumber2);
                cfprocparam(type = "IN", cfsqltype = "CF_SQL_VARCHAR", value = transactionStruct.newTokenString);
                cfprocparam(type = "IN", cfsqltype = "CF_SQL_VARCHAR", value = transactionStruct.processor);
                cfprocparam(type = "IN", cfsqltype = "CF_SQL_VARCHAR", value = transactionStruct.ccTransactionId);
                cfprocparam(type = "IN", cfsqltype = "CF_SQL_VARCHAR", value = transactionStruct.ccAddress);
                cfprocparam(type = "IN", cfsqltype = "CF_SQL_VARCHAR", value = transactionStruct.blankField);
                cfprocparam(type = "IN", cfsqltype = "CF_SQL_VARCHAR", value = transactionStruct.ccCity);
                cfprocparam(type = "IN", cfsqltype = "CF_SQL_VARCHAR", value = transactionStruct.ccState);
                cfprocparam(type = "IN", cfsqltype = "CF_SQL_VARCHAR", value = transactionStruct.ccCountry);
                cfprocparam(type = "IN", cfsqltype = "CF_SQL_VARCHAR", value = transactionStruct.ccZipCode);
                cfprocparam(type = "IN", cfsqltype = "CF_SQL_VARCHAR", value = transactionStruct.Email);
            }
            return true;
        } catch (any e) {
            return false;
        }
    }


    public struct function insertReservationComment(required struct commentStruct) {
        var result = {success: false, po_sucess_val: 0, po_msg: ''};
        try {
            cfstoredproc(procedure = "insert_reservation_comment", datasource = "prcgold") {
                cfprocparam(type = "in", cfsqltype = "CF_SQL_NUMERIC", value = commentStruct.SandalsBookingNumber);
                cfprocparam(type = "in", cfsqltype = "CF_SQL_VARCHAR", value = commentStruct.commentText);
                cfprocparam(type = "in", cfsqltype = "CF_SQL_VARCHAR", value = commentStruct.source);
                cfprocparam(type = "out", cfsqltype = "CF_SQL_NUMERIC", variable = "po_sucess_val");
                cfprocparam(type = "out", cfsqltype = "CF_SQL_VARCHAR", variable = "po_msg");
                cfprocparam(type = "in", cfsqltype = "CF_SQL_VARCHAR", value = commentStruct.emptyString);
            }
            result.success = true;
            result.po_sucess_val = po_sucess_val;
            result.po_msg = po_msg;
        } catch (any e) {
            result.success = false;
            result.po_sucess_val = 0;
            result.po_msg = e.message;
        }
        return result;
    }

}
