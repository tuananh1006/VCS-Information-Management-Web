import userService from '../service/userService'

const handHelloWorld=(req, res) => {
    const name='Eric';
    return res.render('home.ejs',{name})
}

const handleTeam=(req,res)=>{
    var clubs=[{
        name:'Tun',
        wins:1,
        draws:1,
        losts:1,
        goalsFor:1,
        goalsAgainst:1,
        goalsDiff:1,
        point:1
    }]
    return res.render('team.ejs',{clubs})
}

const handleAddUser=(req,res)=>{
    let userList=userService.getUserList()
    return res.render('user-add.ejs',{userList})
}

const handleCreateUser=(req,res)=>{
    let email=req.body.email
    let password=req.body.password
    let username=req.body.username

    return res.redirect('/users/')
}
module.exports={
    handHelloWorld,handleTeam,handleAddUser,handleCreateUser
}