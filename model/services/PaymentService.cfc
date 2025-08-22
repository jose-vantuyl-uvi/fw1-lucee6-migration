component accessors="true" {

    property BookingDataProvider;
    property Shift4Factory;

    public query function getCountries() {
        var rtnStruct = getBookingDataProvider().getCountries().results;
        return rtnStruct;
    }

    public string function enrollAutoCharge(required numeric rdo_ccs, required string txtBookingNumber) {
        var sErrorMessage2 = getPaymentDataProvider().enrollAutoCharge(
            rdo_ccs = arguments.rdo_ccs,
            txtBookingNumber = arguments.txtBookingNumber
        );
        return sErrorMessage2;
    }

    public struct function verifyBooking(required string Email, required numeric BookingNumber) {
        var structResults = getBookingDataProvider().VerifyBooking(
            Email = arguments.Email,
            BookingNumber = arguments.BookingNumber
        );
        return structResults;
    }

    public query function getCCTypes() {
        ccTypes = getShift4Factory().getCCTypes();
        return ccTypes;
    }

    public string function getCCCodeById(required numeric p_typeid, required query p_qryCCtypes) {
        ccTypeId = getShift4Factory().getCCCodeById(p_typeid, p_qryCCtypes);
        return ccTypeId;
    }

    public string function getCCCode4DBById(required numeric p_typeid, required query p_qryCCtypes) {
        ccTypeId = getShift4Factory().getCCCode4DBById(p_typeid, p_qryCCtypes);
        return ccTypeId;
    }

    public function validateCreditCardType(ccnumber = '', cctype = '', cccvv = '') {
        var output = {cctype: arguments.cctype, message: '', success: false};

        var isValidLength = len(ccnumber) == {2: 16, 1: 16, 3: 15, 4: 16}[arguments.cctype] ?: false;

        var isValidCvvLength = len(cccvv) == {2: 3, 1: 3, 3: 4, 4: 3}[arguments.cctype] ?: false;

        var isValidPrefix = {
            2: left(ccnumber, 1) == 4,
            1: left(ccnumber, 1) == 5 || left(ccnumber, 1) == 2,
            3: left(ccnumber, 1) == 3,
            4: left(ccnumber, 1) == 6
        }[arguments.cctype] ?: false;

        var isValid = isValidLength && isValidCvvLength && isValidPrefix;

        if (!isValid) {
            output.message = {
                2: 'Please use a valid VISA credit card',
                1: 'Please use a valid MASTER CARD credit card',
                3: 'Please use a valid AMEX credit card',
                4: 'Please use a valid credit card'
            }[arguments.cctype] ?: 'Please use a valid credit card';
            return output;
        }

        output.success = true;
        return output;
    }


    public struct function checkGroupBooking(
        required string BookingNumber,
        required string GroupName,
        required date CheckInDate,
        required string ResortCode
    ) {
        var ThisReturn = getBookingDataProvider().CheckGroupBooking(
            BookingNumber = arguments.BookingNumber,
            GroupName = arguments.GroupName,
            CheckInDate = arguments.CheckInDate,
            ResortCode = arguments.ResortCode
        );
        return ThisReturn;
    }


}
