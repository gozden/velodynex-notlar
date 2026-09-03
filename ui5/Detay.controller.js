sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/m/MessageToast",
  "sap/ui/core/routing/History"
], function (Controller, MessageToast, History) {
  "use strict";

  return Controller.extend("vdx.notlar.Detay", {

    _t: function (sKey, aArgs) {
      return this.getView().getModel("i18n").getResourceBundle().getText(sKey, aArgs);
    },

    onInit: function () {
      this.getOwnerComponent().getRouter()
        .getRoute("detay")
        .attachPatternMatched(this._onRouteMatched, this);
    },

    _onRouteMatched: function (oEvent) {
      var sNotId = oEvent.getParameter("arguments").notId;
      this.getView().bindElement("/NotlarSet('" + sNotId + "')");
    },

    onKaydet: function () {
      var that = this;
      var oModel = this.getView().getModel();

      if (!oModel.hasPendingChanges()) {
        MessageToast.show(this._t("msgDegisiklikYok"));
        return;
      }

      oModel.submitChanges({
        success: function () {
          MessageToast.show(that._t("msgKaydedildi"));
          that.onGeri();
        },
        error: function () { MessageToast.show(that._t("msgKaydetHata")); }
      });
    },

    onGeri: function () {
      var oModel = this.getView().getModel();
      if (oModel.hasPendingChanges()) {
        oModel.resetChanges();
      }
      var sPrevious = History.getInstance().getPreviousHash();
      if (sPrevious !== undefined) {
        window.history.go(-1);
      } else {
        this.getOwnerComponent().getRouter().navTo("liste", {}, true);
      }
    }

  });
});
