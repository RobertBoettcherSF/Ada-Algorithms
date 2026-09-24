pragma SPARK_Mode (On);
package body Design_HashMap is
   function Empty return Map is
   begin
      return (Values => (others => 0), Used => (others => False));
   end Empty;
   procedure Put (M : in out Map; K : Key; V : Value) is
   begin
      M.Values (K) := V;
      M.Used (K) := True;
   end Put;
   function Contains (M : Map; K : Key) return Boolean is
   begin
      return M.Used (K);
   end Contains;
   function Get (M : Map; K : Key) return Value is
   begin
      return M.Values (K);
   end Get;
end Design_HashMap;
