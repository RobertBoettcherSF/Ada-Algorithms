package body Huangs_Algorithm is

   -- Epsilon threshold to prevent floating-point underflow/precision issues
   Epsilon : constant Weight_Type := 1.0e-9;

   function Is_Virtually_Equal (W1, W2 : Weight_Type) return Boolean is
   begin
      return abs (W1 - W2) < Epsilon;
   end Is_Virtually_Equal;

   procedure Initialize (Sys : out System_State; Initiator : Node_ID) is
   begin
      -- Set all nodes to idle
      for I in Sys.Nodes'Range loop
         Sys.Nodes(I).ID := I;
         Sys.Nodes(I).State := Idle;
         Sys.Nodes(I).Weight := 0.0;
      end loop;
      
      -- Bootstrap the initiator agent with Weight W = 1.0
      Sys.Initiator := Initiator;
      Sys.Nodes(Initiator).State := Active;
      Sys.Nodes(Initiator).Weight := 1.0;
   end Initialize;

   procedure Send_Message_Static (Sys : in out System_State; From : Node_ID; W_Msg : out Weight_Type) is
   begin
      if Sys.Nodes(From).State = Idle then
         raise Invalid_Operation with "Idle node cannot send a message";
      end if;
      if Sys.Nodes(From).Weight <= Epsilon then
         raise Invalid_Operation with "Weight too small to split, risk of underflow";
      end if;

      -- Split weight exactly in half (W1 + W2 = W)
      W_Msg := Sys.Nodes(From).Weight / 2.0;
      Sys.Nodes(From).Weight := Sys.Nodes(From).Weight - W_Msg;
   end Send_Message_Static;

   procedure Send_Message_Dynamic (Sys : in out System_State; From : Node_ID; Fraction : Long_Float; W_Msg : out Weight_Type) is
   begin
      if Sys.Nodes(From).State = Idle then
         raise Invalid_Operation with "Idle node cannot send a message";
      end if;
      if Fraction <= 0.0 or Fraction >= 1.0 then
         raise Invalid_Operation with "Fraction must be between 0.0 and 1.0 exclusive";
      end if;

      W_Msg := Sys.Nodes(From).Weight * Weight_Type(Fraction);
      
      -- Edge Case validation
      if Sys.Nodes(From).Weight - W_Msg <= Epsilon or W_Msg <= Epsilon then
         raise Invalid_Operation with "Weight split resulted in floating-point underflow";
      end if;

      Sys.Nodes(From).Weight := Sys.Nodes(From).Weight - W_Msg;
   end Send_Message_Dynamic;

   procedure Receive_Message (Sys : in out System_State; At_Node : Node_ID; W_Msg : Weight_Type) is
   begin
      if W_Msg <= 0.0 then
         raise Invalid_Operation with "Received weight must be strictly positive";
      end if;
      
      Sys.Nodes(At_Node).State := Active;
      Sys.Nodes(At_Node).Weight := Sys.Nodes(At_Node).Weight + W_Msg;
   end Receive_Message;

   procedure Finish_Task (Sys : in out System_State; At_Node : Node_ID; W_Ret : out Weight_Type) is
   begin
      if Sys.Nodes(At_Node).State = Idle then
         raise Invalid_Operation with "Node is already idle, cannot finish task";
      end if;
      
      W_Ret := Sys.Nodes(At_Node).Weight;
      Sys.Nodes(At_Node).Weight := 0.0;
      Sys.Nodes(At_Node).State := Idle;
   end Finish_Task;

   procedure Receive_Returned_Weight (Sys : in out System_State; W_Ret : Weight_Type) is
   begin
      if W_Ret <= 0.0 then
         raise Invalid_Operation with "Returned weight must be strictly positive";
      end if;
      -- Initiator accumulates returned weight to deduce global termination
      Sys.Nodes(Sys.Initiator).Weight := Sys.Nodes(Sys.Initiator).Weight + W_Ret;
   end Receive_Returned_Weight;

   function Is_Terminated (Sys : System_State) return Boolean is
   begin
      -- Termination achieved iff Initiator is idle and has recovered Weight W = 1.0
      return Sys.Nodes(Sys.Initiator).State = Idle
             and then Is_Virtually_Equal (Sys.Nodes(Sys.Initiator).Weight, 1.0);
   end Is_Terminated;

end Huangs_Algorithm;
