// Fragment event handlers for OData-backed Value Help
// Add these methods to your controller

onVHOpen: function () {
  if (!this._oVHDialog) {
    this._oVHDialog = this.loadFragment({ name: "com.example.myapp.fragment.BookVH" });
  }
  this._oVHDialog.then(function (d) {
    d.getBinding("items").filter([]);
    d.open();
  });
},

onVHSearch: function (oEvent) {
  var sValue = oEvent.getParameter("value");
  var oFilter = sValue
    ? new sap.ui.model.Filter("title", sap.ui.model.FilterOperator.Contains, sValue)
    : null;
  oEvent.getSource().getBinding("items").filter(oFilter ? [oFilter] : []);
},

onVHConfirm: function (oEvent) {
  var oCtx = oEvent.getParameter("selectedContexts")[0];
  this.byId("bookInput").setValue(oCtx.getProperty("title"));
  this._oVHDialog.then(d => d.getBinding("items").filter([]));
}
