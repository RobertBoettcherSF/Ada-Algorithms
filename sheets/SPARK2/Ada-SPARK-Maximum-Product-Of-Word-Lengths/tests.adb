pragma Ada_2022;
with Maximum_Product_Of_Word_Lengths;
procedure Tests is
begin
   pragma Assert (Maximum_Product_Of_Word_Lengths.Product_Of_Two (4, 5) = 20);
   pragma Assert (Maximum_Product_Of_Word_Lengths.Maximum_Product (4, 5, 8, 2) = 20);
   pragma Assert (Maximum_Product_Of_Word_Lengths.Maximum_Product (12, 12, 1, 128) = 144);
end Tests;
