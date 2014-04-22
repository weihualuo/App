

angular.module('MESSAGE', [])
  .constant('MESSAGE',
    LOAD_FAILED: '加载失败'
    NO_MORE:     '没有更多了'
    SUBMITTING:   '正在提交...'
    UPLOADING:   '正在上传图片...'
    SUBMIT_FAILED: '提交失败'
    UPLOAD_FAILED: '上传失败'
    EMAIL_VALID: '请输入正确的邮件地址'
    MINLEN_PWD: '密码最少长度为6'
    REQ_USRNAME: '请输入用户名'
    REQ_EMAIL:  '请输入邮件地址'
    REQ_PWD: '请输入密码'
    LOGIN_OK: '登录成功'
    LOGIN_NOK: '不正确的用户名或密码'
    REGISTER_OK: '注册成功'
    USRNAME_EXIST: '用户名已存在'
  )
  .constant('Config',
    $meta:
      imgbase: "http://houzz-imgs.stor.sinaapp.com/"
      style: []
      room: []
      location: []
    $filter:
      room:
        title: '空间'
        any:
          id: 0
          en: 'All spaces'
          cn: '所有空间'
      style:
        title: '风格'
        any:
          id: 0
          en: 'Any Style'
          cn: '所有风格'
      location:
        title: '地点'
        any:
          id: 0
          en: 'Any Area'
          cn: '全部地点'
  )

