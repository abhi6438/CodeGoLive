sap.ui.define(["sap/ui/core/mvc/Controller"], function (Controller) {
  "use strict";
  return Controller.extend("com.example.myapp.controller.Main", {
    onItemPress: function (oEvent) {
      var sId = oEvent.getSource().getBindingContext().getProperty("id");
      this.getOwnerComponent().getRouter().navTo("detail", { id: sId });
    }
  });
});
