--  Static registry: category → algorithm name + test binary basename.
--  Extend this when migrating more sheet repos into the monorepo.

pragma Ada_2022;

package Categories is

   type Category_Id is (Sorting, Searching);

   function Category_Label (C : Category_Id) return String;
   --  Lowercase directory-style name: "sorting", "searching".

   function Parse_Category (S : String) return Category_Id;
   --  Case-insensitive parse of label; raises Constraint_Error if unknown.

   type Algo_Index is range 1 .. 32;

   type Algo_Entry is record
      Name      : String (1 .. 32);
      Name_Len  : Natural;
      Category  : Category_Id;
      Test_Bin  : String (1 .. 32);  -- basename under bin/, e.g. test_quicksort
      Bin_Len   : Natural;
   end record;

   function Registry_Length return Natural;
   function Get (I : Algo_Index) return Algo_Entry
     with Pre => Natural (I) <= Registry_Length;

   function Name_Of (E : Algo_Entry) return String;
   function Bin_Of  (E : Algo_Entry) return String;

end Categories;
