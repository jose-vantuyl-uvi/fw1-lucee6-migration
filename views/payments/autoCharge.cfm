<table width="100%" cellpadding="0" cellspacing="0" bgcolor="#f5f5f5" border="0" id="pageholder" align="center">
    <tr>
        <!--- Main Content --->
        <td valign="top" align="center">
            <table
                width="500"
                cellpadding="0"
                cellspacing="0"
                title="Sandals and Beaches Online Payment"
                align="center" style="margin-top:20px; "
            >
                <tr>
                    <td>
                        <img src="/assets/images/payment-title.gif" width="500" height="23">
                    </td>
                </tr>
                <tr>
                    <td>
                        <cfoutput>
                            <form
                                name="BookingSearchForm"
                                method="post"
                                action="#CGI.SCRIPT_NAME#"
                                onSubmit="Verify();return false"
                            >
                                <br>
                                <table
                                    align="center"
                                    width="500"
                                    border="0"
                                    cellpadding="2"
                                    cellspacing="0"
                                    bordercolor="FFFFFF"
                                >
                                    <tr>
                                        <td colspan="2">
                                            <div class="indent" style="margin-bottom:20px; ">
                                                #Client.ccSelectedMessage#
                                            </div>
                                        </td>
                                    </tr>
                                </table>
                            </form>
                        </cfoutput>
                    </td>
                </tr>
            </table>
        </td>
    </tr>
</table>
