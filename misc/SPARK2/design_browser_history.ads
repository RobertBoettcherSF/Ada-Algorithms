pragma SPARK_Mode (On);
package Design_Browser_History is
   Capacity : constant := 4;
   subtype Page is Positive range 1 .. 100;
   subtype Count is Natural range 0 .. Capacity;
   type History is private;
   function Empty return History with Global => null;
   function Length (H : History) return Count with Global => null;
   function Current_Index (H : History) return Count with Global => null;
   procedure Visit (H : in out History; P : Page) with Global => null,
     Pre => Current_Index (H) = Length (H) and Length (H) < Capacity;
   procedure Back (H : in out History) with Global => null,
     Pre => Current_Index (H) > 1;
   procedure Forward (H : in out History) with Global => null,
     Pre => Current_Index (H) < Length (H);
   function Current_Page (H : History) return Page with Global => null,
     Pre => Current_Index (H) > 0;
private
   subtype Index is Count;
   type Page_Array is array (Index) of Page;
   type History is record
      Pages : Page_Array := (others => 1);
      Size : Count := 0;
      Current : Count := 0;
   end record;
end Design_Browser_History;
