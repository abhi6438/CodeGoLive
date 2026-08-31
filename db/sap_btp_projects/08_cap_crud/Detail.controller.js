sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/m/MessageToast",
  "sap/m/MessageBox"
], function (Controller, MessageToast, MessageBox) {
  "use strict";
  return Controller.extend("com.example.bookshop.controller.Detail", {
    onInit: function () {
      this.getOwnerComponent().getRouter()
        .getRoute("detail")
        .attachPatternMatched(this._onRouteMatched, this);
    },
    _onRouteMatched: function (oEvent) {
      var sKey = decodeURIComponent(oEvent.getParameter("arguments").key);
      this.getView().bindElement({ path: sKey, parameters: { $$updateGroupId: "$auto" } });
    },
    onSave: function () {
      this.getView().getModel().submitBatch("$auto")
        .then(() => MessageToast.show("Saved"))
        .catch(e => MessageToast.show("Error: " + e.message));
    },
    onDelete: function () {
      MessageBox.confirm("Delete this book?", { onClose: (a) => {
        if (a === "OK") {
          this.getView().getBindingContext().delete("$auto")
            .then(() => this.getOwnerComponent().getRouter().navTo("main"));
        }
      }});
    }
  });
});
