sap.ui.define(["sap/ui/core/mvc/Controller"], function (Controller) {
  "use strict";
  return Controller.extend("com.example.myapp.controller.Detail", {
    onInit: function () {
      this.getOwnerComponent().getRouter()
        .getRoute("detail")
        .attachPatternMatched(this._onRouteMatched, this);
    },
    _onRouteMatched: function (oEvent) {
      var iId = parseInt(oEvent.getParameter("arguments").id);
      this.getView().bindElement("/products/" + iId);
    },
    onBack: function () {
      this.getOwnerComponent().getRouter().navTo("main");
    }
  });
});
