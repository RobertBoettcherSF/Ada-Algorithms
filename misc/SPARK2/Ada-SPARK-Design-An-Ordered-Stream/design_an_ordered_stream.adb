pragma SPARK_Mode (On);
package body Design_An_Ordered_Stream is
   function Empty return Stream is
   begin
      return (Values => (others => 0), Present => (others => False), Cursor => 1);
   end Empty;
   procedure Put (S : in out Stream; P : Position; V : Item) is
   begin
      S.Values (P) := V;
      S.Present (P) := True;
   end Put;
   function Ready (S : Stream) return Boolean is
   begin
      return S.Cursor <= Capacity and then S.Present (S.Cursor);
   end Ready;
   function Read (S : Stream) return Item is
   begin
      return S.Values (S.Cursor);
   end Read;
   procedure Advance (S : in out Stream) is
   begin
      S.Present (S.Cursor) := False;
      case S.Cursor is
         when 1 => S.Cursor := 2;
         when 2 => S.Cursor := 3;
         when 3 => S.Cursor := 4;
         when 4 => null;
      end case;
   end Advance;
end Design_An_Ordered_Stream;
