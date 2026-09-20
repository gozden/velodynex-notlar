sap.ui.define(["sap/m/MessageBox"], function (MessageBox) {
    "use strict";
    return {
        onOzet: function (oContext) {
            var oListBinding = oContext.getModel().bindList("_Adimlar", oContext);
            Promise.all([
                oContext.requestObject(),
                oListBinding.requestContexts()
            ]).then(function (aResults) {
                var oNot = aResults[0];
                var iAdim = aResults[1].length;
                MessageBox.information(
                    "Başlık: " + oNot.Baslik +
                    "\nDurum: " + oNot.DurumText +
                    "\nOluşturan: " + oNot.CreatedBy +
                    "\nAdım sayısı: " + iAdim,
                    { title: "Not Özeti" });
            });
        }
    };
});