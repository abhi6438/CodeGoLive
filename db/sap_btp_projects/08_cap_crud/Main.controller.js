sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/m/MessageToast"
], function (Controller, MessageToast) {
  "use strict";
  return Controller.extend("com.example.bookshop.controller.Main", {
    onItemPress: function (oEvent) {
      var sPath = oEvent.getSource().getBindingContextPath();
      var sKey = encodeURIComponent(sPath);
      this.getOwnerComponent().getRouter().navTo("detail", { key: sKey });
    },
    onCreateBook: function () {
      var oModel = this.getView().getModel();
      var oListBinding = oModel.bindList("/Books");
      var oCtx = oListBinding.create({
        title: "New Book", author: "Author", stock: 0, price: 0
      });
      oCtx.created().then(() => {
        MessageToast.show("Book created");
        this.byId("bookList").getBinding("items").refresh();
      }).catch(e => console.error(e));
    }
  });
});
