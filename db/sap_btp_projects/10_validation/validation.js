// Reusable validation helpers for SAPUI5
// Paste into your controller

_validateInput: function (oInput, sMessage) {
  if (!oInput.getValue().trim()) {
    oInput.setValueState("Error");
    oInput.setValueStateText(sMessage || "This field is required");
    return false;
  }
  oInput.setValueState("None");
  return true;
},

_validateForm: function (aInputIds) {
  return aInputIds.every(function (sId) {
    return this._validateInput(this.byId(sId));
  }.bind(this));
},

onSave: function () {
  if (!this._validateForm(["titleInput", "authorInput"])) {
    sap.m.MessageToast.show("Please fix validation errors");
    return;
  }
  // proceed with OData save
  this.getView().getModel().submitBatch("$auto")
    .then(() => sap.m.MessageToast.show("Saved successfully"))
    .catch(e => sap.m.MessageBox.error(e.message));
},

onDelete: function () {
  sap.m.MessageBox.confirm("Delete this item?", {
    title: "Confirm Delete",
    onClose: function (sAction) {
      if (sAction === sap.m.MessageBox.Action.OK) {
        this.getView().getBindingContext().delete("$auto")
          .then(() => this.getOwnerComponent().getRouter().navTo("main"));
      }
    }.bind(this)
  });
}
