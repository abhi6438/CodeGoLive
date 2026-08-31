namespace my.bookshop;
using { cuid, managed } from '@sap/cds/common';

entity Books : cuid, managed {
  title  : String(111);
  author : String(111);
  stock  : Integer;
  price  : Decimal(9,2);
}
