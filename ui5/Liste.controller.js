sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/m/MessageToast",
  "sap/m/Dialog",
  "sap/m/Input",
  "sap/m/Button",
  "sap/m/MessageBox",
  "sap/ui/model/Filter",
  "sap/ui/model/FilterOperator",
  "sap/ui/model/Sorter",
  "sap/ui/model/json/JSONModel"
], function (Controller, MessageToast, Dialog, Input, Button, MessageBox,
             Filter, FilterOperator, Sorter, JSONModel) {
  "use strict";

  return Controller.extend("vdx.notlar.Liste", {

    _t: function (sKey, aArgs) {
      return this.getView().getModel("i18n").getResourceBundle().getText(sKey, aArgs);
    },

    onInit: function () {
      this._sSekme = "TUMU";
      this._sArama = "";
      this._bTariheGore = true;
      this.getView().setModel(new JSONModel({ tumu: 0, acik: 0, tamam: 0 }), "sayac");
    },

    // ---------- Filtre / sıralama ----------

    _filtreleriUygula: function () {
      var aFiltreler = [];

      if (this._sSekme !== "TUMU") {
        aFiltreler.push(new Filter("Durum", FilterOperator.EQ, this._sSekme));
      }
      if (this._sArama) {
        aFiltreler.push(new Filter("Baslik", FilterOperator.Contains, this._sArama));
      }

      var oBinding = this.byId("notListesi").getBinding("items");
      oBinding.filter(aFiltreler.length ? new Filter({ filters: aFiltreler, and: true }) : []);
    },

    onAra: function (oEvent) {
      this._sArama = oEvent.getParameter("newValue");
      this._filtreleriUygula();
    },

    onSekme: function (oEvent) {
      this._sSekme = oEvent.getParameter("key");
      this._filtreleriUygula();
    },

    onSirala: function () {
      this._bTariheGore = !this._bTariheGore;
      var oSorter = this._bTariheGore
        ? new Sorter("Olusturma", true)   // yeni → eski
        : new Sorter("Baslik", false);    // A → Z
      this.byId("notListesi").getBinding("items").sort(oSorter);
      MessageToast.show(this._bTariheGore ? this._t("sortTarih") : this._t("sortBaslik"));
    },

    // ---------- Sekme sayaçları ----------

    onListeGuncellendi: function () {
      this._sayaclariGuncelle();
    },

    _sayaclariGuncelle: function () {
      var oModel = this.getView().getModel();
      var oSayac = this.getView().getModel("sayac");

      var fnSay = function (sAlan, aFiltre) {
        oModel.read("/NotlarSet/$count", {
          filters: aFiltre,
          success: function (iSayi) { oSayac.setProperty("/" + sAlan, parseInt(iSayi, 10)); }
        });
      };

      fnSay("tumu", []);
      fnSay("acik",  [new Filter("Durum", FilterOperator.EQ, "A")]);
      fnSay("tamam", [new Filter("Durum", FilterOperator.EQ, "T")]);
    },

    // ---------- Navigasyon ----------

    onDetay: function (oEvent) {
      var sNotId = oEvent.getSource().getBindingContext().getProperty("NotId");
      this.getOwnerComponent().getRouter().navTo("detay", { notId: sNotId });
    },

    // ---------- CRUD ----------

    onYeniNot: function () {
      var that = this;
      var oInput = new Input({ placeholder: this._t("inpPlaceholder"), width: "100%" });

      var oDialog = new Dialog({
        title: this._t("dlgYeniNotBaslik"),
        content: [oInput],
        beginButton: new Button({
          text: this._t("btnKaydet"),
          type: "Emphasized",
          press: function () {
            var sBaslik = oInput.getValue();
            if (!sBaslik) { MessageToast.show(that._t("msgBaslikBos")); return; }
            that.getView().getModel().create("/NotlarSet",
              { Baslik: sBaslik },
              {
                success: function () { MessageToast.show(that._t("msgEklendi")); },
                error: function () { MessageToast.show(that._t("msgEklemeHata")); }
              });
            oDialog.close();
          }
        }),
        endButton: new Button({
          text: this._t("btnVazgec"),
          press: function () { oDialog.close(); }
        }),
        afterClose: function () { oDialog.destroy(); }
      });

      oDialog.open();
    },

    onSil: function (oEvent) {
      var that = this;
      var oContext = oEvent.getParameter("listItem").getBindingContext();
      var sPath = oContext.getPath();
      var sBaslik = oContext.getProperty("Baslik");

      MessageBox.confirm(this._t("msgSilOnay", [sBaslik]), {
        onClose: function (sAction) {
          if (sAction === MessageBox.Action.OK) {
            that.getView().getModel().remove(sPath, {
              success: function () { MessageToast.show(that._t("msgSilindi")); },
              error: function () { MessageToast.show(that._t("msgSilmeHata")); }
            });
          }
        }
      });
    }

  });
});
