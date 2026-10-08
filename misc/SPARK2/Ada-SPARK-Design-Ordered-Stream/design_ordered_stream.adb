pragma SPARK_Mode (On);
package body Design_Ordered_Stream is
   function Empty return Stream is
   begin
      return (Values => (others => 0), Present => (others => False), Cursor => 1);
   end Empty;
   procedure Insert (S : in out Stream; P : Position; V : Item) is
   begin
      S.Values (P) := V;
      S.Present (P) := True;
   end Insert;
   function Has_Next (S : Stream) return Boolean is
   begin
      return S.Cursor <= Capacity and then S.Present (S.Cursor);
   end Has_Next;
   function Next (S : Stream) return Item is
   begin
      return S.Values (S.Cursor);
   end Next;
   procedure Consume (S : in out Stream) is
   begin
      S.Present (S.Cursor) := False;
      case S.Cursor is
         when 1 => S.Cursor := 2;
         when 2 => S.Cursor := 3;
         when 3 => S.Cursor := 4;
         when 4 => S.Cursor := 5;
         when 5 => null;
      end case;
   end Consume;
end Design_Ordered_Stream;
