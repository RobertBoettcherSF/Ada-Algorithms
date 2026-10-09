pragma Ada_2022;
pragma SPARK_Mode (On);
package body Design_Browser_History is
   function Empty return History is
   begin
      return (Pages => [others => 1], Size => 0, Current => 0);
   end Empty;
   procedure Visit (H : in out History; P : Page) is
   begin
      H.Current := H.Current + 1;
      H.Pages (H.Current) := P;
      H.Size := H.Current;
   end Visit;
   procedure Back (H : in out History) is
   begin
      H.Current := H.Current - 1;
   end Back;
   procedure Forward (H : in out History) is
   begin
      H.Current := H.Current + 1;
   end Forward;
   function Current_Page (H : History) return Page is
   begin
      return H.Pages (H.Current);
   end Current_Page;
end Design_Browser_History;
