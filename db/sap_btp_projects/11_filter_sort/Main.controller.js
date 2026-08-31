sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/ui/model/Filter",
  "sap/ui/model/FilterOperator",
  "sap/ui/model/Sorter"
], function (Controller, Filter, FilterOperator, Sorter) {
  "use strict";
  return Controller.extend("com.example.bookshop.controller.Main", {
    _bSortAsc: true,

    onSearch: function (oEvent) {
      var sQuery = oEvent.getParameter("query");
      var oBinding = this.byId("bookList").getBinding("items");
      if (sQuery) {
        oBinding.filter([new Filter({
          filters: [
            new Filter("title",  FilterOperator.Contains, sQuery),
            new Filter("author", FilterOperator.Contains, sQuery)
          ],
          and: false
        })]);
      } else {
        oBinding.filter([]);
      }
    },

    onSort: function () {
      this._bSortAsc = !this._bSortAsc;
      var oBinding = this.byId("bookList").getBinding("items");
      oBinding.sort(new Sorter("title", !this._bSortAsc));
    },

    onSortByPrice: function () {
      var oBinding = this.byId("bookList").getBinding("items");
      oBinding.sort(new Sorter("price", true));  // descending
    }
  });
});
