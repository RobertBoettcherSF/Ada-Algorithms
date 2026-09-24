-- paxos.adb
package body Paxos is

   function ">" (Left, Right : Proposal_ID) return Boolean is
   begin
      if Left.Number > Right.Number then
         return True;
      elsif Left.Number = Right.Number then
         return Left.Node > Right.Node;
      else
         return False;
      end if;
   end ">";

   function ">=" (Left, Right : Proposal_ID) return Boolean is
   begin
      return (Left > Right) or else (Left = Right);
   end ">=";

   -------------------------------------------------
   -- Basic Paxos Implementation
   -------------------------------------------------
   procedure Basic_Paxos_Prepare
     (Acceptor : in out Acceptor_State;
      Proposal : in Proposal_ID;
      Response : out Promise_Response)
   is
   begin
      -- An acceptor only promises if the proposal is strictly greater 
      -- than any it has previously promised to.
      if Proposal > Acceptor.Min_Proposal then
         Acceptor.Min_Proposal := Proposal;
         Response.Ack := True;
         Response.Previous_Proposal := Acceptor.Accepted_Proposal;
         Response.Previous_Value := Acceptor.Accepted_Value;
      else
         Response.Ack := False;
         Response.Previous_Proposal := (0, 0);
         Response.Previous_Value := Null_Value;
      end if;
   end Basic_Paxos_Prepare;

   procedure Basic_Paxos_Accept
     (Acceptor : in out Acceptor_State;
      Proposal : in Proposal_ID;
      Value    : in Value_Type;
      Accepted : out Boolean)
   is
   begin
      -- An acceptor accepts a proposal if it has not promised to 
      -- ignore proposals with this ID.
      if Proposal >= Acceptor.Min_Proposal then
         Acceptor.Min_Proposal := Proposal;
         Acceptor.Accepted_Proposal := Proposal;
         Acceptor.Accepted_Value := Value;
         Accepted := True;
      else
         Accepted := False;
      end if;
   end Basic_Paxos_Accept;

   -------------------------------------------------
   -- Multi-Paxos Implementation
   -------------------------------------------------
   procedure Multi_Paxos_Accept
     (Acceptors : in out Multi_Acceptor_Array;
      Instance  : in Instance_ID;
      Proposal  : in Proposal_ID;
      Value     : in Value_Type;
      Accepted  : out Boolean)
   is
   begin
      if Instance not in Acceptors'Range then
         raise Invalid_Instance;
      end if;
      
      -- Multi-Paxos applies basic rules to specific log instances
      Basic_Paxos_Accept(Acceptors(Instance), Proposal, Value, Accepted);
   end Multi_Paxos_Accept;

   -------------------------------------------------
   -- Fast Paxos Implementation
   -------------------------------------------------
   procedure Fast_Paxos_Any_Accept
     (Acceptor : in out Acceptor_State;
      Value    : in Value_Type;
      Accepted : out Boolean)
   is
   begin
      -- In Fast Paxos, clients bypass phase 1 if the Acceptor is waiting on 'Any'
      if Acceptor.Min_Proposal = (0, 0) or else Acceptor.Min_Proposal = Fast_Proposal then
         Acceptor.Min_Proposal := Fast_Proposal;
         Acceptor.Accepted_Proposal := Fast_Proposal;
         Acceptor.Accepted_Value := Value;
         Accepted := True;
      else
         Accepted := False;
      end if;
   end Fast_Paxos_Any_Accept;

   -------------------------------------------------
   -- Cheap Paxos Implementation
   -------------------------------------------------
   procedure Cheap_Paxos_Accept
     (Acceptor   : in out Acceptor_State;
      Role       : in Node_Role;
      Main_Is_Up : in Boolean;
      Proposal   : in Proposal_ID;
      Value      : in Value_Type;
      Accepted   : out Boolean)
   is
   begin
      -- Auxiliary nodes only accept if they detect the Main Quorum is compromised
      if Role = Auxiliary and then Main_Is_Up then
         Accepted := False;
         return;
      end if;
      
      -- Standard accept behavior
      Basic_Paxos_Accept(Acceptor, Proposal, Value, Accepted);
   end Cheap_Paxos_Accept;

end Paxos;
