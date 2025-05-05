
use v5.40;

package X::DB {

    use utf8::all;
    use Moo;
    use Carp qw(croak);
    use Teng::Schema::Loader;
    use DBI;

    # Teng インスタンス
    has teng => (
        is       => 'ro',
        required => 1,
    );

    sub connect_database( $class, $db_path ) {
        say "データベースに接続します: $db_path";

        # DBディレクトリが存在しない場合は作成
        my $db_dir = $db_path;
        $db_dir =~ s|/[^/]+$||;
        if ( !-d $db_dir ) {
            say "DBディレクトリを作成します: $db_dir";
            mkdir $db_dir or die "DBディレクトリの作成に失敗しました: $db_dir ($!)";
        }

# DB接続
# @note AutoCommit => 1 にするのは奇妙に思えるが、DBD::SQLite3の仕様上正しい。
#
# @url https://perldoc.jp/docs/modules/DBD-SQLite-1.29/SQLite.pod#Transactions
# @url https://stackoverflow.com/questions/55064603/perl-dbi-sqlite-commit-or-detach-fails-when-autocommit-is-set-to-false
#
        my $dbh = DBI->connect(
            "dbi:SQLite:dbname=$db_path",
            "", "",
            {
                RaiseError     => 1,
                PrintError     => 0,
                AutoCommit     => 1,
                sqlite_unicode => 1,
            }
        ) or die $DBI::errstr;

        # Tengスキーマをロード
        my $teng = Teng::Schema::Loader->load(
            dbh       => $dbh,
            namespace => 'MyApp::DB',
        );

        say "データベース接続が完了しました";
        return $class->new( teng => $teng );
    }

    # テーブル名を返す（サブクラスでオーバーライドする）
    sub table_name ($self) {
        croak "table_name method must be implemented in subclass"
          unless $self->table;
    }

    sub execute( $self, $sql, $binds = [] ) {
        if ( scalar(@$binds) ) {
            $self->teng->execute( $sql, $binds );
        }
        else {
            $self->teng->execute($sql);
        }
    }

    # 全てのレコードを取得する
    sub find_all ( $self, $table, $option = {} ) {
        my @rows = $self->teng->search( $table, {}, $option );

        return \@rows;
    }

    # IDで1件取得する
    sub find_by_id ( $self, $table, $id ) {
        my $row = $self->teng->single( $table, { 'id' => $id } );
        return $row;
    }

    # 条件に合致するレコードを取得する
    sub find_by ( $self, $table, $condition ) {
        my $row = $self->teng->single( $table, $condition );
        return $row;
    }

    # SQLを直接実行して検索する
    sub find_by_sql ( $self, $table, $sql, $binds = [], $option = {} ) {
        my @rows = $self->teng->search_by_sql( $sql, $binds, $table );
        return \@rows;
    }

    # 条件に合致するレコードを取得する
    sub where ( $self, $table, $cond, $option = {} ) {
        my @rows = $self->teng->search( $table, $cond, $option );
        return \@rows;
    }

    # 1件追加する
    sub create ( $self, $table, $data ) {
        my $row = $self->teng->insert( $table, $data );
        return $row;
    }

    # １件追加する。 create メソッドの alias
    sub insert( $self, $table, $data ) {
        return $self->create( $table, $data );
    }

    # 検索してなければ作成する。
    sub find_or_create( $self, $table, $data, $cond ) {
        my $row = $self->find_by( $table, $cond );
        return $row if $row;
        return $self->create( $table, $data );
    }

    # レコードを更新する。更新したあとに、更新後の$rowを返す。
    sub update_and_find( $self, $table, $id, $data ) {
        my $row = $self->teng->single( $table, { id => $id } );

        $row->update( $table, $data );
        return $row;
    }

    # レコードが存在するかをチェックする。
    sub exists( $self, $table, $cond ) {
        my $row = $self->find_by( $table, $cond );

        if ($row) {
            return 1;
        }
        else {
            return 0;
        }
    }

    # 検索条件に一致するレコードがあれば更新、なければ作成する
    sub upsert ( $self, $table, $data, $search_condition ) {

        # 検索条件に一致するレコードを検索
        my $row = $self->find_by($search_condition);

        # レコードが存在する場合は更新
        if ($row) {
            my $id_val = $row->get_column('id');

            # 主キーを検索条件から取得して更新
            $self->update( $table, $id_val, $data );

            # 更新後のレコードを再取得して返す
            return $self->find_by_id( $table, $id_val );
        }

        # レコードが存在しない場合は新規作成
        else {
            # 検索条件のデータも含めてレコードを作成
            my $merged_data = { %$search_condition, %$data };
            my $row         = $self->create( $table, $merged_data );
            return $row;
        }
    }

    # レコードを更新する
    sub update ( $self, $table, $id, $data ) {
        my $result = $self->teng->update( $table, $data, { 'id' => $id } );
        return $result;
    }

    # レコードを削除する
    sub delete ( $self, $table, $id ) {
        my $result = $self->teng->delete( $table, { 'id' => $id } );
        return $result;
    }

    # 条件に合致するレコードを削除する
    sub delete_by ( $self, $table, $condition ) {
        my $result = $self->teng->delete( $table, $condition );
        return $result;
    }

    sub total_count( $self, $table ) {
        my @rows = $self->teng->search( $table, +{} );
        return scalar(@rows);
    }

    sub begin_trans($self) { $self->teng->txn_begin; }

    sub commit($self) { $self->teng->txn_commit; }

    sub rollback($self) { $self->teng->txn_rollback; }
}

1;

=pod 

=encoding utf8

=head1 名前

X::DB - データベース操作を抽象化するクラス

=head1 概略

このモジュールはデータベース操作を抽象化し、SQLiteデータベースへの接続と基本的なCRUD操作を提供する。
Tengフレームワークを利用してデータベース操作を行う。

=head1 メソッド

=head2 connect_database

    my $db = X::DB->connect_database($db_path);

指定されたパスにSQLiteデータベースを接続する。

- パラメータ:
  - $db_path: String - 接続するデータベースファイルのパス
- 戻り値:
  - X::DB - 初期化されたデータベースオブジェクト

=head2 table_name

    $self->table_name();

テーブル名を返す。サブクラスでオーバーライドする必要がある。

- パラメータ: なし
- 戻り値:
  - String - テーブル名

=head2 execute

    $self->execute($sql, $binds);

SQLを直接実行する。

- パラメータ:
  - $sql: String - 実行するSQL文
  - $binds: ArrayRef - プレースホルダにバインドする値の配列（オプション）
- 戻り値:
  - 実行結果

=head2 find_all

    my $rows = $self->find_all($table, $option);

テーブルの全レコードを取得する。

- パラメータ:
  - $table: String - テーブル名
  - $option: HashRef - 検索オプション（オプション）
- 戻り値:
  - ArrayRef - レコードの配列

=head2 find_by_id

    my $row = $self->find_by_id($table, $id);

指定されたIDのレコードを1件取得する。

- パラメータ:
  - $table: String - テーブル名
  - $id: Integer - 検索するレコードのID
- 戻り値:
  - Object - 見つかったレコード、または undef

=head2 find_by

    my $row = $self->find_by($table, $condition);

指定された条件に合致するレコードを1件取得する。

- パラメータ:
  - $table: String - テーブル名
  - $condition: HashRef - 検索条件
- 戻り値:
  - Object - 見つかったレコード、または undef

=head2 find_by_sql

    my $rows = $self->find_by_sql($table, $sql, $binds, $option);

SQLを直接実行して検索する。

- パラメータ:
  - $table: String - テーブル名
  - $sql: String - 実行するSQL文
  - $binds: ArrayRef - プレースホルダにバインドする値の配列（オプション）
  - $option: HashRef - 検索オプション（オプション）
- 戻り値:
  - ArrayRef - 見つかったレコードの配列

=head2 where

    my $rows = $self->where($table, $cond, $option);

条件に合致するレコードを複数取得する。

- パラメータ:
  - $table: String - テーブル名
  - $cond: HashRef - 検索条件
  - $option: HashRef - 検索オプション（オプション）
- 戻り値:
  - ArrayRef - 見つかったレコードの配列

=head2 create

    my $row = $self->create($table, $data);

レコードを1件追加する。

- パラメータ:
  - $table: String - テーブル名
  - $data: HashRef - 挿入するデータ
- 戻り値:
  - Object - 挿入されたレコード

=head2 insert

    my $row = $self->insert($table, $data);

レコードを1件追加する。createメソッドのエイリアス。

- パラメータ:
  - $table: String - テーブル名
  - $data: HashRef - 挿入するデータ
- 戻り値:
  - Object - 挿入されたレコード

=head2 find_or_create

    my $row = $self->find_or_create($table, $data, $cond);

条件に合致するレコードを検索し、なければ新規作成する。

- パラメータ:
  - $table: String - テーブル名
  - $data: HashRef - 挿入するデータ
  - $cond: HashRef - 検索条件
- 戻り値:
  - Object - 見つかったまたは作成されたレコード

=head2 update_and_find

    my $row = $self->update_and_find($table, $id, $data);

レコードを更新し、更新後のレコードを返す。

- パラメータ:
  - $table: String - テーブル名
  - $id: Integer - 更新するレコードのID
  - $data: HashRef - 更新するデータ
- 戻り値:
  - Object - 更新後のレコード

=head2 exists

    my $exists = $self->exists($table, $cond);

レコードが存在するかを確認する。

- パラメータ:
  - $table: String - テーブル名
  - $cond: HashRef - 検索条件
- 戻り値:
  - Boolean - 存在すれば1、存在しなければ0

=head2 upsert

    my $row = $self->upsert($table, $data, $search_condition);

検索条件に一致するレコードがあれば更新し、なければ新規作成する。

- パラメータ:
  - $table: String - テーブル名
  - $data: HashRef - 更新または挿入するデータ
  - $search_condition: HashRef - 検索条件
- 戻り値:
  - Object - 更新または作成されたレコード

=head2 update

    my $result = $self->update($table, $id, $data);

指定されたIDのレコードを更新する。

- パラメータ:
  - $table: String - テーブル名
  - $id: Integer - 更新するレコードのID
  - $data: HashRef - 更新するデータ
- 戻り値:
  - Integer - 更新された行数

=head2 delete

    my $result = $self->delete($table, $id);

指定されたIDのレコードを削除する。

- パラメータ:
  - $table: String - テーブル名
  - $id: Integer - 削除するレコードのID
- 戻り値:
  - Integer - 削除された行数

=head2 delete_by

    my $result = $self->delete_by($table, $condition);

条件に合致するレコードを削除する。

- パラメータ:
  - $table: String - テーブル名
  - $condition: HashRef - 削除条件
- 戻り値:
  - Integer - 削除された行数

=head2 total_count

    my $count = $self->total_count($table);

テーブルの全レコード数を取得する。

- パラメータ:
  - $table: String - テーブル名
- 戻り値:
  - Integer - レコード総数

=head2 begin_trans

    $self->begin_trans();

トランザクションを開始する。

- パラメータ: なし
- 戻り値: なし

=head2 commit

    $self->commit();

トランザクションをコミットする。

- パラメータ: なし
- 戻り値: なし

=head2 rollback

    $self->rollback();

トランザクションをロールバックする。

- パラメータ: なし
- 戻り値: なし

=head1 属性

=head2 teng

Tengインスタンス。

- 型: Object
- 必須: あり

=head2 primary_key

主キーの名前。デフォルトは "id"。

- 型: String
- 必須: あり
- デフォルト: "id"

=cut
