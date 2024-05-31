const handHelloWorld=(req, res) => {
    const name='Eric';
    return res.render('home.ejs',{name})
}

const handleTeam=(req,res)=>{
    var clubs={
        name:'Tun',
        wins:1,
        draws:1,
        losts:1,
        goalsFor:1,
        goalsAgainst:1,
        goalsDiff:1,
        point:1
    }
    return res.render('team.ejs',{clubs:clubs})
}
module.exports={
    handHelloWorld,handleTeam
}