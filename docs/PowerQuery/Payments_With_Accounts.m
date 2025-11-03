let
    // 1) Start from standardized payments
    Payments = Payments_Normalize,

    // 2) Derive GAK for payments (Granite uses MACNUM == AccountNo)
    //    We trim/upper to make joins stable.
    AddGAK =
        Table.AddColumn(
            Payments,
            "GAK",
            each let a = [AccountNo] in if a=null then null else Text.Upper(Text.Trim(Text.From(a))),
            type text
        ),

    // 3) Bring in Accounts
    Accts = Accounts_Load,

    // 4) Left join on GAK
    Merged = Table.NestedJoin(
        AddGAK,
        {"GAK"},
        Accts,
        {"GAK"},
        "Acct",
        JoinKind.LeftOuter
    ),

    // 5) Expand a focused set of account fields (we won't overwrite payment fields)
    Expanded = Table.ExpandTableColumn(
        Merged,
        "Acct",
        {"Customer","Payor","Carrier","PrimaryAgent","SalesChannel","Status","StartMonth","EndMonth"},
        {"Acct_Customer","Acct_Payor","Acct_Carrier","Acct_PrimaryAgent","Acct_SalesChannel","Acct_Status","Acct_StartMonth","Acct_EndMonth"}
    ),

    // 6) QA flags
    MissingAccount = Table.AddColumn(Expanded, "MissingAccount", each 
        [Acct_PrimaryAgent] = null and [Acct_Status] = null and [Acct_StartMonth] = null, // no match expanded
        type logical
    ),

    AccountOutOfRange = Table.AddColumn(MissingAccount, "AccountOutOfRange", each 
        let cm = try Date.From([CommissionMonth]) otherwise null,
            s  = [Acct_StartMonth],
            e  = [Acct_EndMonth]
        in if [MissingAccount] or cm=null or s=null or e=null then false else (cm < s or cm > e),
        type logical
    ),

    // 7) Types & tidy column order
    Typed = Table.TransformColumnTypes(
        AccountOutOfRange,
        {
            {"Acct_StartMonth", type date},
            {"Acct_EndMonth", type date}
        },
        "en-US"
    ),

    Final = Table.ReorderColumns(
        Typed,
        {
            "CommissionMonth","PayorRptDate","Payor","Carrier","Customer","AccountNo","GAK","Product","LineType","GrossAmt","Memo","FileID","BatchId",
            "Acct_Customer","Acct_Payor","Acct_Carrier","Acct_PrimaryAgent","Acct_SalesChannel","Acct_Status","Acct_StartMonth","Acct_EndMonth",
            "MissingAccount","AccountOutOfRange"
        },
        MissingField.UseNull
    )
in
    Final