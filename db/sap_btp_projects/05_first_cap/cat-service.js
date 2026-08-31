const cds = require('@sap/cds');
module.exports = cds.service.impl(async function () {
  this.before("CREATE", "Books", (req) => {
    if (!req.data.title) req.error(400, "Title is required");
    if (req.data.price < 0) req.error(400, "Price must be positive");
  });
  this.after("READ", "Books", (books) => {
    console.log(`Returning ${books.length} books`);
  });
});
