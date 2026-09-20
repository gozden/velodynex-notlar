sap.ui.define([
    "sap/ui/core/mvc/ControllerExtension",
    "sap/m/MessageToast"
], function (ControllerExtension, MessageToast) {
    "use strict";
    return ControllerExtension.extend("zvdx.notfe4.ext.controller.ObjectPageExt", {
        override: {
            onPageReady: function () {
                var oCtx = this.base.getView().getBindingContext();
                if (oCtx) {
                    MessageToast.show("Not sayfası hazır — controller extension");
                }
            }
        }
    });
});