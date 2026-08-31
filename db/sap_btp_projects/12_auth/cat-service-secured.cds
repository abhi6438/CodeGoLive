using my.bookshop as my from '../db/schema';

@requires: 'viewer'
service CatalogService {
  @readonly entity Books as projection on my.Books;
}

@requires: 'admin'
service AdminService {
  entity Books as projection on my.Books;
}
