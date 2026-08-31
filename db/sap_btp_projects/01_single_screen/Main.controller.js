sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/ui/model/json/JSONModel"
], function (Controller, JSONModel) {
  "use strict";
  return Controller.extend("com.example.myapp.controller.Main", {
    onInit: function () {
      this.getView().setModel(new JSONModel({
        products: [
          { name: "Laptop",   price: "€999" },
          { name: "Monitor",  price: "€349" },
          { name: "Keyboard", price: "€79"  }
        ]
      }));
    }
  });
});
