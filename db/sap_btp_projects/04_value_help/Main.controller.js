sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/ui/model/json/JSONModel",
  "sap/ui/model/Filter",
  "sap/ui/model/FilterOperator"
], function (Controller, JSONModel, Filter, FilterOperator) {
  "use strict";
  return Controller.extend("com.example.myapp.controller.Main", {
    onInit: function () {
      this.getView().setModel(new JSONModel({
        customers: [
          { id: "C001", name: "Acme Corp" },
          { id: "C002", name: "Globex" },
          { id: "C003", name: "Initech" }
        ]
      }));
    },
    onVHOpen: function () {
      if (!this._oVHDialog) {
        this._oVHDialog = this.loadFragment({ name: "com.example.myapp.fragment.CustomerVH" });
      }
      this._oVHDialog.then(d => { d.getBinding("items").filter([]); d.open(); });
    },
    onVHSearch: function (oEvent) {
      var sVal = oEvent.getParameter("value");
      oEvent.getSource().getBinding("items").filter(
        sVal ? [new Filter("name", FilterOperator.Contains, sVal)] : []
      );
    },
    onVHConfirm: function (oEvent) {
      var oCtx = oEvent.getParameter("selectedContexts")[0];
      this.byId("customerInput").setValue(oCtx.getProperty("name"));
    }
  });
});
