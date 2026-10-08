pragma SPARK_Mode (On);
package body Design_Browser_History is
   function Empty return History is
   begin
      return (Pages => (others => 1), Size => 0, Current => 0);
   end Empty;
   function Length (H : History) return Count is
   begin
      return H.Size;
   end Length;
   function Current_Index (H : History) return Count is
   begin
      return H.Current;
   end Current_Index;
   procedure Visit (H : in out History; P : Page) is
   begin
      case H.Size is
         when 0 => H.Pages (1) := P;
         when 1 => H.Pages (2) := P;
         when 2 => H.Pages (3) := P;
         when 3 => H.Pages (4) := P;
         when 4 => null;
      end case;
      if H.Size < Capacity then H.Size := H.Size + 1; end if;
      H.Current := H.Size;
   end Visit;
   procedure Back (H : in out History) is
   begin
      if H.Current > 0 then H.Current := H.Current - 1; end if;
   end Back;
   procedure Forward (H : in out History) is
   begin
      if H.Current < Capacity then H.Current := H.Current + 1; end if;
   end Forward;
   function Current_Page (H : History) return Page is
   begin
      return H.Pages (H.Current);
   end Current_Page;
end Design_Browser_History;
