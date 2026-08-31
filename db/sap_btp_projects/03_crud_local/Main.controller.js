sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/ui/model/json/JSONModel",
  "sap/m/MessageBox"
], function (Controller, JSONModel, MessageBox) {
  "use strict";
  return Controller.extend("com.example.myapp.controller.Main", {
    onInit: function () {
      this.getView().setModel(new JSONModel({ products: [
        { name: "Laptop", price: "€999" },
        { name: "Monitor", price: "€349" }
      ]}));
    },
    onAdd: function () {
      if (!this._oDialog) {
        this._oDialog = this.loadFragment({ name: "com.example.myapp.fragment.AddProduct" });
      }
      this._oDialog.then(d => d.open());
    },
    onSave: function () {
      var oModel = this.getView().getModel();
      var aProducts = oModel.getProperty("/products");
      aProducts.push({
        name: this.byId("nameInput").getValue(),
        price: this.byId("priceInput").getValue()
      });
      oModel.setProperty("/products", aProducts);
      this.byId("addDialog").close();
    },
    onCancel: function () { this.byId("addDialog").close(); },
    onDelete: function (oEvent) {
      var iIdx = parseInt(oEvent.getSource().getBindingContext().getPath().split("/").pop());
      MessageBox.confirm("Delete this item?", { onClose: (a) => {
        if (a === "OK") {
          var oModel = this.getView().getModel();
          var a2 = oModel.getProperty("/products");
          a2.splice(iIdx, 1);
          oModel.setProperty("/products", a2);
        }
      }});
    }
  });
});
