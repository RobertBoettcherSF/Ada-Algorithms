pragma Ada_2022;

package body Job_Table
  with SPARK_Mode => On
is

   procedure Clear (T : out Table) is
   begin
      T :=
        (Stack     => [for I in 1 .. Max_Jobs => Valid_Job_Id (I)],
         Top       => Max_Jobs,
         Live      => [others => False],
         Completed => [others => False],
         Requests  => [others => (Kind => Nop, Arg => 0)]);
   end Clear;

   procedure Allocate
     (T       : in out Table;
      Request : Job_Request;
      Id      : out Job_Id)
   is
      J : Valid_Job_Id;
   begin
      J := T.Stack (T.Top);
      T.Top := T.Top - 1;
      T.Live (J) := True;
      T.Completed (J) := False;
      T.Requests (J) := Request;
      Id := J;
   end Allocate;

   procedure Complete (T : in out Table; Id : Valid_Job_Id) is
   begin
      T.Live (Id) := False;
      T.Completed (Id) := True;
      T.Top := T.Top + 1;
      T.Stack (T.Top) := Id;
   end Complete;

   procedure Acknowledge (T : in out Table; Id : Valid_Job_Id) is
   begin
      T.Completed (Id) := False;
   end Acknowledge;

end Job_Table;
