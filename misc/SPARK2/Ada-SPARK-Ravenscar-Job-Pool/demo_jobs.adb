pragma Ada_2022;

with Channel;
with Channel.Sync;

package body Demo_Jobs
  with SPARK_Mode => Off
is
   --  Shared mutable state guarded by a protected object (tasking clients).
   protected State is
      procedure Reset;
      procedure Add (D : Integer);
      function Get return Integer;
      procedure Set_Ping (V : Integer);
      function Get_Ping return Integer;
   private
      Counter : Integer := 0;
      Ping    : Integer := 0;
   end State;

   protected body State is
      procedure Reset is
      begin
         Counter := 0;
         Ping := 0;
      end Reset;

      procedure Add (D : Integer) is
      begin
         Counter := Counter + D;
      end Add;

      function Get return Integer is (Counter);

      procedure Set_Ping (V : Integer) is
      begin
         Ping := V;
      end Set_Ping;

      function Get_Ping return Integer is (Ping);
   end State;

   procedure Reset is
   begin
      State.Reset;
      Channel.Sync.PO.Reset;
   end Reset;

   procedure Increment_Counter (Delta_Value : Integer) is
   begin
      State.Add (Delta_Value);
   end Increment_Counter;

   function Counter_Value return Integer is
   begin
      return State.Get;
   end Counter_Value;

   procedure Ping_Channel (Arg : Integer) is
      Got : Integer;
   begin
      Channel.Sync.PO.Enqueue (Arg);
      Channel.Sync.PO.Dequeue (Got);
      State.Set_Ping (Got);
   end Ping_Channel;

   function Last_Ping return Integer is
   begin
      return State.Get_Ping;
   end Last_Ping;

end Demo_Jobs;
